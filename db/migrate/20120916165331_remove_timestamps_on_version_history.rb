class RemoveTimestampsOnVersionHistory < ActiveRecord::Migration
  def up
    remove_column :version_histories, :created_at
    remove_column :version_histories, :updated_at
  end

  def down
  end
end
