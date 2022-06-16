class ChangeEntriesQuantityToNumber < ActiveRecord::Migration[7.0]
  def change
    change_column :entries, :qty, 'integer USING CAST(qty AS integer)'
  end
end
