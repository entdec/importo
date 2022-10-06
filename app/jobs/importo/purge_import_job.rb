module Importo
  class PurgeImportJob < ApplicationJob
    def perform(owner, months)
      imports = Import.where(importo_ownable: owner, created_at: ..months.months.ago.beginning_of_day)

      if owner.is_a?(Account) && owner.class.method_defined?(:users)
        account_imports = Importo::Import.distinct.joins('INNER JOIN users on users.id = importo_imports.importo_ownable_id').select('importo_imports.*')
                                         .where(users: { account_id: owner.id }, created_at: ..months.months.ago.beginning_of_day)
        account_imports.in_batches.destroy_all
      end

      imports.in_batches.destroy_all
    end
  end
end
