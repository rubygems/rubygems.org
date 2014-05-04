class AddLanguageToUsers < ActiveRecord::Migration
  def change
    add_column :users, :language, :string, :null => false, :default => "en"
  end
end
