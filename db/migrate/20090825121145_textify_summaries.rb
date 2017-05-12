class TextifySummaries < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :versions, :summary
    add_column :versions, :summary, :text
  end

  def self.down
    remove_column :versions, :summary
    add_column :versions, :summary, :string
  end
end
