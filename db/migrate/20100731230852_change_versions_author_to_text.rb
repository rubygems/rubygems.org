class ChangeVersionsAuthorToText < ActiveRecord::Migration[4.2]
  def self.up
    change_column :versions, :authors, :text
  end

  def self.down
    change_column :versions, :authors, :string
  end
end
