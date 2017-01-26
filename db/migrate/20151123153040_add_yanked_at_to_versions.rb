class AddYankedAtToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :yanked_at, :datetime
  end
end
