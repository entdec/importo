module Importo
  class ImportJob < Importo.config.import_job_base_class.safe_constantize
    # No options here, gets added from the adapter

    def perform(attributes, index, import_id)
      self.class.execute_row(attributes, index, import_id, false, bid)
    end

    def self.execute_row(attributes, index, import_id, last_attempt, bid)
      attributes = JSON.load(attributes).deep_symbolize_keys if attributes.is_a?(String)

      import = Import.find(import_id)
      import.importer.process_data_row(attributes, index, last_attempt: last_attempt)

      # Between sidekiq and good job, there's a big difference:
      # - Sidekiq calls on_complete callback when all jobs ran at least once.
      # - GoodJob calls on_complete callback when all jobs are done (including retries).
      # i.e. this logic is only needed for sidekiq
      if Importo.config.batch_adapter == Importo::SidekiqBatchAdapter
        batch = Importo::SidekiqBatchAdapter.find(bid)

        if !import.completed? && import.can_complete? && batch.finished?
          ImportJobCallback.new.on_complete(:complete, {import_id: import.id})
        end
      end
    end
  end
end
