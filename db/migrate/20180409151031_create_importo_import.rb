class CreateImportoImport < ActiveRecord::Migration[5.1]
  def change
    enable_extension 'uuid-ossp'
    enable_extension 'pgcrypto'

    create_table :importo_imports, id: :uuid do |t|
      t.string  :importo_ownable_type, null: false
      t.uuid    :importo_ownable_id, null: false

      t.string  :kind
      t.string  :state
      t.string  :file_name
      t.string  :result_message
      t.jsonb   :results

      t.timestamps
    end
  end
end
