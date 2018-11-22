class RemoveRawFromDownloads < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :downloads, :raw
  end

  def self.down
    add_column :downloads, :raw, :string
  end
end
