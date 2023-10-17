class RemoveTimestampsOnVersionHistory < ActiveRecord::Migration[4.2]
  def up
    remove_column :version_histories, :created_at # rubocop:disable Rails/BulkChangeTable
    remove_column :version_histories, :updated_at
  end

  def down
  end
end
