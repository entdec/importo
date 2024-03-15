require "test_helper"

class AccountImporter < Importo::BaseImporter
  includes_header true
  allow_duplicates false

  model Account

  column attribute: "id"
  column attribute: "name"
  column attribute: "description", strip_tags: false
end

module Importo
  class PurgeImportJobTest < ActiveSupport::TestCase
    test "does not purge importo import less than 3 month ago" do
      account = Account.create(name: "test")
      import = Import.new(importo_ownable: account, kind: "account", created_at: 1.month.ago)
      import.original.attach(io: simple_sheet([%w[id name description], %w[aid atest atest-description]]),
        filename: "simple_sheet.xlsx")
      import.save!

      PurgeImportJob.perform_now(account, 3)

      assert import.reload
    end

    test "purges imporoto import message more than 3 month ago" do
      account = Account.create(name: "test")
      import = Import.new(importo_ownable: account, kind: "account", created_at: 5.month.ago)
      import.original.attach(io: simple_sheet([%w[id name description], %w[aid atest atest-description]]),
        filename: "simple_sheet.xlsx")
      import.save!

      PurgeImportJob.perform_now(account, 3)

      assert import.original.attached?

      assert_raises ActiveRecord::RecordNotFound do
        import.reload
      end
    end
  end
end
