class AddMetadataToVersions < ActiveRecord::Migration
  def change
    enable_extension 'hstore'

    add_column :versions, :metadata, :hstore, default: {}, null: false
  end
end
