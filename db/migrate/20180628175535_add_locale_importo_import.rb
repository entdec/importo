class AddLocaleImportoImport < ActiveRecord::Migration[5.1]
  def change
    return if column_exists?(:importo_imports, :locale)

    add_column :importo_imports, :locale, :string, default: "en"
  end
end
