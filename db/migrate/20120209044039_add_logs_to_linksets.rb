class AddLogsToLinksets < ActiveRecord::Migration
  def self.up
    add_column :linksets, :logs, :string
  end

  def self.down
    remove_column :linksets, :logs
  end
end
