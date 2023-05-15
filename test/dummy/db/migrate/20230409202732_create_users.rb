class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    enable_extension 'uuid-ossp'
    enable_extension 'pgcrypto'
    
    create_table :users, id: :uuid  do |t|
      t.string :name
      t.string :description
      t.timestamps
    end
  end
end
