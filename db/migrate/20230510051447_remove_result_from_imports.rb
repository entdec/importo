class RemoveResultFromImports < ActiveRecord::Migration[7.0]
  def change
    remove_column :importo_imports, :results, :jsonb
  end
end
