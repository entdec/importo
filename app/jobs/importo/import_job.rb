module Importo
  class ImportJob
    include Sidekiq::Job
    sidekiq_options retry: 5
    # queue_as :integration
    queue_as Importo.config.queue_name

    sidekiq_retries_exhausted do |msg, _e|
      attributes = msg['args'][0]
      index = msg['args'][1]
      import_id = msg['args'][2]
      signal_id = msg['args'][3]

      execute_row(attributes, index, import_id, signal_id, true, msg['bid'])
    end

    def perform(attributes, index, import_id, signal_id)
      self.class.execute_row(attributes, index, import_id, signal_id, false, bid)

      # puts "Working within batch #{bid}"
      # batch.jobs do
      # add more jobs
      # end
    end

    def self.execute_row(attributes, index, import_id, signal_id, last_attempt, bid)
      attributes = JSON.load(attributes).deep_symbolize_keys if attributes.is_a?(String)

      import = Import.find(import_id)
      record = import.importer.process_data_row(attributes, index, last_attempt: last_attempt)

      signal = Signum::Signal.find(signal_id)
      signal.increment!(:count)
      signal.update(text: "Importing #{import.original.filename}")

      # Signum::SendSignalsJob.perform_now(signal, true)

      batch = Sidekiq::Batch.new(bid)

      if batch.status.pending - 1 <= 0

        if import.results.where('details @> ?', '{"state":"failure"}').any?
          signal.update(text: "Failed to import #{import.original.filename}")
        else
          signal.update(text: "Completed import of #{import.original.filename}")
        end

        ImportJobCallback.new.on_complete(batch.status, { import_id: import_id, signal_id: signal_id })
      end
    end
  end
end
