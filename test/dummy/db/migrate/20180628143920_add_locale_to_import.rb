class AddLocaleToImport < ActiveRecord::Migration[5.1]
  def change
    add_column :imports, :locale, :string, default: 'en'
  end
end
