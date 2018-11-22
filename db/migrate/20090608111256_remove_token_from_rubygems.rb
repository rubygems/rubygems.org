class RemoveTokenFromRubygems < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :rubygems, :token
  end

  def self.down
    add_column :rubygems, :token, :string
  end
end
