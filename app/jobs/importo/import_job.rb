module Importo
  class ImportJob < Importo.config.import_job_base_class.constantize
    # No options here, gets added from the adapter

    def perform(attributes, index, import_id)
      self.class.execute_row(attributes, index, import_id, false, defined?(bid) ? bid : batch.id)
    end

    def self.execute_row(attributes, index, import_id, last_attempt, bid)
      attributes = JSON.load(attributes).deep_symbolize_keys if attributes.is_a?(String)

      import = Import.find(import_id)
      import.importer.process_data_row(attributes, index, last_attempt: last_attempt)

      # This should not be needed:
      # https://github.com/sidekiq/sidekiq/wiki/Batches#callbacks
      #
      # Between sidekiq and good job, there's a big difference:
      # - Sidekiq calls on_complete callback when all jobs ran at least once.
      # - GoodJob calls on_complete callback when all jobs are done (including retries).
      # i.e. this logic is only needed for sidekiq
      # return unless Importo.sidekiq?

      # batch = Importo::SidekiqBatchAdapter.find(bid)

      # if !import.completed? && import.can_complete? && batch.finished?
      #   ImportJobCallback.perform_now(batch, import.id)
      # end
    end
  end
end
