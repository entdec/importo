module Importo
  class PurgeImportJob < ApplicationJob
    def perform(owner, months,state = nil)

      imports = Import.where(importo_ownable: owner, created_at: ..months.months.ago.beginning_of_day)
      imports = imports.where(state: state) if state

      imports.each do |import|
        import.original.purge
        import.result.purge
      end

      imports.in_batches.destroy_all
    end
  end
end
