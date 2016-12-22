class AddPushedByToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :pushed_by, :string
  end
end
