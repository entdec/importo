module Importo
  class ImportScheduleJob
    include Sidekiq::Job

    def perform(import_id)
      ImportService.perform(import: Import.find(import_id))
    end
  end
end
