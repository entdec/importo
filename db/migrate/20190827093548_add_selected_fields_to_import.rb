class AddSelectedFieldsToImport < ActiveRecord::Migration[5.2]
  def change
    add_column :importo_imports, :column_overrides, :jsonb, default: {}, null: false
  end
end
