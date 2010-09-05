class ChangeVersionsAuthorToText < ActiveRecord::Migration
  def self.up
    change_column :versions, :authors, :text
  end

  def self.down
    change_column :versions, :authors, :string
  end
end
