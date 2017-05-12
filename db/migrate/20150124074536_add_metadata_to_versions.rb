class AddMetadataToVersions < ActiveRecord::Migration[4.2]
  def change
    enable_extension 'hstore'

    add_column :versions, :metadata, :hstore, default: {}, null: false
  end
end
