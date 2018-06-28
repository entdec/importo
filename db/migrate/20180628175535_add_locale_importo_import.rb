class AddLocaleImportoImport < ActiveRecord::Migration[5.1]
  def change
    add_column :importo_imports, :locale, :string, default: 'en'
  end
end
