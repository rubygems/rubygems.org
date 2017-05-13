class CreateRubygems < ActiveRecord::Migration[4.2]
  def self.up
    create_table :rubygems do |table|
      table.string :name
      table.string :token
      table.integer :user_id
      table.timestamps
    end
  end

  def self.down
    drop_table :rubygems
  end
end
