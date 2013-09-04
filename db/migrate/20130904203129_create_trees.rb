class CreateTrees < ActiveRecord::Migration
  def change
    create_table :trees do |t|
      t.integer :version_id
      t.string :state
      t.integer :runtime_weight
      t.integer :development_weight
      t.text :data
      t.text :tree_data

      t.timestamps
    end

    add_index :trees, :version_id
  end
end
