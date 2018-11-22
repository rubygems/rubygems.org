class AddLatestToVersion < ActiveRecord::Migration[4.2]
  def self.up
    add_column :versions, :latest, :boolean

    Rubygem.all.each(&:reorder_versions)
  end

  def self.down
    remove_column :versions, :latest
  end
end
