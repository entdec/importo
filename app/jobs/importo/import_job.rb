module Importo
  class ImportJob
    include Sidekiq::Job

    def perform(attributes, index, import_id, signal_id)
      attributes = JSON.load(attributes).deep_symbolize_keys if attributes.is_a?(String)

      import = Import.find(import_id)
      record = import.importer.process_data_row(attributes, index)

      signal = Signum::Signal.find(signal_id)
      signal.increment!(:count)
      signal.reload

      Signum::SendSignalsJob.perform_now(signal, false)

      # puts "Working within batch #{bid}"
      # batch.jobs do
      # add more jobs
      # end
    end
  end
end
