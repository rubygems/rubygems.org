class RemoveRawFromDownloads < ActiveRecord::Migration
  def self.up
    remove_column :downloads, :raw
  end

  def self.down
    add_column :downloads, :raw, :string
  end
end
