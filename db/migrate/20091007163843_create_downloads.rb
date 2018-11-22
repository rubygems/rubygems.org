class CreateDownloads < ActiveRecord::Migration[4.2]
  def self.up
    create_table :downloads do |table|
      table.string :raw
      table.belongs_to :version
      table.timestamps
    end

    add_index :downloads, :version_id
  end

  def self.down
    remove_index :downloads, :version_id
    drop_table :downloads
  end
end
