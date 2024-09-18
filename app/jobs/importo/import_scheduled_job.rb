module Importo
  class ImportScheduledJob < ApplicationJob
    def perform()
      imports = Import.where(state: "scheduled", created_at: ..30.minutes.ago)

      imports.each do |import|
        ImportService.perform_async(import: import)
      end
    end
  end
end
