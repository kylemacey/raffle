class CreateEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :entries do |t|
      t.string :name
      t.string :phone
      t.string :qty
      t.belongs_to :event, null: false, foreign_key: true

      t.timestamps
    end
  end
end
