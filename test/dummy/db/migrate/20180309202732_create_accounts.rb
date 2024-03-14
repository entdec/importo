class CreateAccounts < ActiveRecord::Migration[5.1]
  def change
    enable_extension "uuid-ossp"
    enable_extension "pgcrypto"
    create_table :accounts, id: :uuid do |t|
      t.string :name
      t.string :description
      t.timestamps
    end
  end
end
