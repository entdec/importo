module Importo
  class ImportRevertJob
    include Sidekiq::Job

    def perform(import_id)
      RevertService.perform(import: Import.find(import_id))
    end
  end
end
