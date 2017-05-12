class AddRequirementsToVersions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :versions, :requirements, :string
  end

  def self.down
    add_column :versions, :requirements, :string
  end
end
