class AddAccessLevelToOwnership < ActiveRecord::Migration[7.1]
  def change
    add_column :ownerships, :access_level, :integer, null: false, default: 70 # Access::OWNER
  end
end
