class AddSocialLinkToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :social_link, :string
  end
end
