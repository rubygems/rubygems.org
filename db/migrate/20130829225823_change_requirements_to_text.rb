class ChangeRequirementsToText < ActiveRecord::Migration
  def up
    change_column :versions, :requirements, :text
  end

  def down
    change_column :versions, :requirements, :string
  end
end
