module Importo
  class ImportJob < ApplicationJob
    queue_as Importo.config.queue_name
    include GoodJob::ActiveJobExtensions::Batches

    # retry_on Importo::RetryError do |job, error|
    #   attributes = job["args"][0]
    #   index = job["args"][1]
    #   import_id = job["args"][2]

    #   binding.break

    #   execute_row(attributes, index, import_id, true, job["bid"])
    # end

    def perform(attributes, index, import_id)
      batch_id = if defined?(bid)
        bid
      else
        batch.id
      end
      batch

      self.class.execute_row(attributes, index, import_id, false, batch_id)
    end

    def self.execute_row(attributes, index, import_id, last_attempt, bid)
      attributes = JSON.load(attributes).deep_symbolize_keys if attributes.is_a?(String)

      import = Import.find(import_id)
      record = import.importer.process_data_row(attributes, index, last_attempt: last_attempt)

      batch = Importo.config.batch_adapter.find(bid)

      # Obsolete
      # if !import.completed? && import.can_complete? && batch.finished?
      #   ImportJobCallback.perform_now(import)
      # end
    end
  end
end
