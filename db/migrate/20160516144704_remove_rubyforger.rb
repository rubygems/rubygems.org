class RemoveRubyforger < ActiveRecord::Migration[4.2]
  def up
    drop_table :rubyforgers
    remove_column :versions, :rubyforge_project
  end

  def down
    create_table :rubyforgers do |t|
      t.string :email
      t.string :encrypted_password, limit: 40
    end
    add_column :versions, :rubyforge_project, :string
  end
end
