# This migration comes from signum (originally 20201125175035)
class CreateSignumSignals < ActiveRecord::Migration[6.0]
  def change
    create_table :signum_signals, id: :uuid do |t|
      t.string :state, default: "pending"
      t.references :signalable, polymorphic: true, optional: false, null: false, type: :uuid

      t.string :kind, default: "notice"
      t.boolean :sticky
      t.string :icon
      t.string :title
      t.text :text

      t.timestamps
    end
  end
end
