class AddSummaryAndRubyforgeProjectToVersions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :versions, :summary, :string
    add_column :versions, :rubyforge_project, :string
  end

  def self.down
    remove_column :versions, :summary, :rubyforge_project
  end
end
