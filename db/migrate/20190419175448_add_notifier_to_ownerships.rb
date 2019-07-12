class AddNotifierToOwnerships < ActiveRecord::Migration[5.2]
  def change
    add_column :ownerships, :notifier, :boolean, default: true, null: false
  end
end
