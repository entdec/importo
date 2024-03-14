class CreateImportoResults < ActiveRecord::Migration[7.0]
  def change
    create_table :importo_results, id: :uuid do |t|
      t.integer :row_index
      t.references :import, type: :uuid, null: false, foreign_key: {to_table: :importo_imports}
      t.jsonb :details, default: {}

      t.timestamps
    end
  end
end
