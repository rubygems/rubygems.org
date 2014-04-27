class AddGinIndexOnNameToRubygems < ActiveRecord::Migration
  def change
    remove_index :rubygems, name: 'index_rubygems_on_name'
    add_index :rubygems, :name, using: :gin
  end
end
