class AddRequirementsToVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :requirements, :string
  end

  def self.down
    add_column :versions, :requirements, :string
  end
end
