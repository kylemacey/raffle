class CreateWinners < ActiveRecord::Migration[7.0]
  def change
    create_table :winners do |t|
      t.belongs_to :entry, null: false, foreign_key: true
      t.string :prize
      t.boolean :present
      t.text :notes

      t.timestamps
    end
  end
end
