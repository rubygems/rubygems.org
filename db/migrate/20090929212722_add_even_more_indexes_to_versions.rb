class AddEvenMoreIndexesToVersions < ActiveRecord::Migration[4.2]
  def self.up
    add_index :versions, :prerelease
    add_index :versions, :indexed
  end

  def self.down
    remove_index :versions, :prerelease
    remove_index :versions, :indexed
  end
end
