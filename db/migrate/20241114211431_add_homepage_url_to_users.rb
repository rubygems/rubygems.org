class AddHomepageUrlToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :homepage_url, :string
  end
end
