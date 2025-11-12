module Importo
<<<<<<< HEAD
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
=======
  class ImportJob < Importo.config.import_job_base_class.safe_constantize
    # No options here, gets added from the adapter
>>>>>>> d048d2523d7a34048cea04448f43f12338703dc0

    def perform(attributes, index, import_id)
      self.class.execute_row(attributes, index, import_id, false)
    end

    def self.execute_row(attributes, index, import_id, last_attempt)
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
          ImportJobCallback.new.on_complete("success", {import_id: import.id})
        end
      end
    end
  end
end
