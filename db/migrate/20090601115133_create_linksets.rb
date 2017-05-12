class CreateLinksets < ActiveRecord::Migration[4.2]
  def self.up
    create_table :linksets do |table|
      table.integer :rubygem_id
      table.string :home
      table.string :wiki
      table.string :docs
      table.string :mail
      table.string :code
      table.string :bugs
      table.timestamps
    end
  end

  def self.down
    drop_table :linksets
  end
end
