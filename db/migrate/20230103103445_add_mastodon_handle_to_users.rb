class AddMastodonHandleToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :mastodon_handle, :string
  end
end
