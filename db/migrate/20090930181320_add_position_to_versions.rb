class AddPositionToVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :position, :integer

    Rubygem.all.each(&:reorder_versions)
  end

  def self.down
    remove_column :versions, :position
  end
end
