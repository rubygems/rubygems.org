class AddApiKeyToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :api_key, :string
  end

  def self.down
    remove_column :users, :api_key
  end
end
