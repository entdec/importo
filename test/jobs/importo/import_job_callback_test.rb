# frozen_string_literal: true

require "test_helper"
require "importo/test_helpers"

# Importer used to reproduce rows that raise a retryable error on their first
# attempt (as happens for a real ActiveRecord::RecordNotUnique race), so the
# corresponding row is left in the "processing" state, pending a Sidekiq retry.
class FlakyAccountImporter < Importo::BaseImporter
  includes_header true
  allow_duplicates false

  model Account

  column attribute: "id"
  column attribute: "name"
  column attribute: "description"

  class << self
    # Tracks which rows already raised once, so the *next* attempt (the retry) succeeds.
    def retry_tracker
      @retry_tracker ||= {}
    end

    def reset_retry_tracker!
      @retry_tracker = {}
    end
  end

  def before_save(_record, row)
    return unless row[:description].to_s.include?("retry-me")

    tracker = self.class.retry_tracker
    return if tracker[row[:name]]

    tracker[row[:name]] = true
    raise ActiveRecord::RecordNotUnique, "simulated race"
  end
end

module Importo
  class ImportJobCallbackTest < ActiveSupport::TestCase
    include TestHelpers

    setup do
      @owner = Account.create!(name: "test")
      FlakyAccountImporter.reset_retry_tracker!
    end

    test "does not finalize the import while rows are still pending a Sidekiq retry" do
      rows = [%w[id name description]]
      2.times { |i| rows << ["", "ok#{i}", "fine"] }
      9.times { |i| rows << ["", "flaky#{i}", "retry-me"] }
      sheet = simple_sheet(rows)

      import = Importo::Import.new(kind: "flaky_account", importo_ownable: @owner)
      import.original.attach(io: sheet, filename: "import.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", identify: false)
      import.save!
      import.confirm
      import.import

      importer = import.importer
      rows_to_process = []
      importer.send(:loop_data_rows) { |attributes, index| rows_to_process << [attributes, index] }

      # Simulate Sidekiq's first pass over all 11 rows: 2 succeed outright, the
      # other 9 hit a transient error on their first (non-final) attempt and
      # will be retried by Sidekiq later (their Result row is rolled back along
      # with the rest of the row's transaction, so it doesn't exist yet).
      rows_to_process.each do |attributes, index|
        Importo::ImportJob.execute_row(JSON.dump(attributes), index, import.id, false, "bid")
      rescue Importo::RetryError
        # expected: Sidekiq would schedule a retry for this row
      end

      import.reload
      assert_equal 2, import.results.where("details @> ?", {state: "success"}.to_json).count
      assert_equal 2, import.results.count, "9 rows are still awaiting a retry and should have no Result yet"

      # Sidekiq-batch's :complete callback can fire as soon as every row has been
      # attempted once, even though 9 rows are still waiting to be retried.
      Importo::ImportJobCallback.new.complete_import(import)
      import.reload

      refute_equal "completed", import.state, "import should not be finalized while rows are still pending a retry"
      refute_equal "Successfully imported 2 of 11 rows", import.result_message,
        "the premature callback should not have generated a result message"

      # Now the 9 retries run and succeed, so the import is genuinely complete.
      rows_to_process.drop(2).each do |attributes, index|
        Importo::ImportJob.execute_row(JSON.dump(attributes), index, import.id, true, "bid")
      end

      import.reload
      Importo::ImportJobCallback.new.complete_import(import)
      import.reload

      assert_equal "completed", import.state
      assert_equal "Successfully imported 11 of 11 rows", import.result_message
    end
  end
end
