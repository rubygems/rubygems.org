class AddArchivedToRubygem < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :rubygems, :archived, :boolean, default: false, null: false
    add_column :rubygems, :archived_at, :datetime
    add_column :rubygems, :archived_by, :integer
    add_index :rubygems, :archived, algorithm: :concurrently
  end
end
