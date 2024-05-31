class AddApiScopesToApiKeys < ActiveRecord::Migration[7.1]
  def change
    add_column :api_keys, :scopes, :string, array: true
  end
end
