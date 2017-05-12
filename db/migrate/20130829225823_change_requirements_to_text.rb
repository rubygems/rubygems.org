class ChangeRequirementsToText < ActiveRecord::Migration[4.2]
  def up
    change_column :versions, :requirements, :text
  end

  def down
    change_column :versions, :requirements, :string
  end
end
