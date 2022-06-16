class CreateDrawings < ActiveRecord::Migration[7.0]
  def change
    create_table :drawings do |t|
      t.string :slug
      t.belongs_to :event, null: false, foreign_key: true

      t.timestamps
    end
    add_index :drawings, :slug
  end
end
