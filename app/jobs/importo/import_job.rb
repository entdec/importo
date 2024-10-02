module Importo
  class ImportJob
    include Sidekiq::Job
    sidekiq_options retry: 5
    # queue_as :integration
    queue_as Importo.config.queue_name

    sidekiq_retries_exhausted do |msg, _e|
      attributes = msg["args"][0]
      index = msg["args"][1]
      import_id = msg["args"][2]

      execute_row(attributes, index, import_id, true, msg["bid"])
    end

    sidekiq_retry_in do |_count, exception, _jobhash|
      case exception
      when Importo::RetryError
        exception.delay
      end
    end

    def perform(attributes, index, import_id)
      self.class.execute_row(attributes, index, import_id, false, bid)
    end

    def self.execute_row(attributes, index, import_id, last_attempt, bid)
      attributes = JSON.load(attributes).deep_symbolize_keys if attributes.is_a?(String)

      import = Import.find(import_id)
      record = import.importer.process_data_row(attributes, index, last_attempt: last_attempt)

      batch = Importo::SidekiqBatchAdapter.find(bid)

      if !import.completed? && import.can_complete? && batch.finished?
        ImportJobCallback.new.on_complete(batch.status, {import_id: import.id})
      end
    end
  end
end
