class AddRequirements < ActiveRecord::Migration[4.2]
  def self.up
    create_table :requirements  do |t|
      t.integer "version_id"
      t.integer "dependency_id"
    end

    remove_column :dependencies, :name
    add_column :dependencies, :rubygem_id, :integer
  end

  def self.down
    drop_table :requirements
    add_column :dependencies, :name, :string
    remove_column :dependencies, :rubygem_id
  end
end
