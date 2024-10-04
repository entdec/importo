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

      batch = Importo::SidekiqBatchAdapter.find(bid)

      if !import.completed? && import.can_complete? && batch.finished?
        ImportJobCallback.new.on_complete(batch.status, {import_id: import.id})
      end
    end
  end
end
