class RemoveRubygemsDownloads < ActiveRecord::Migration
  def change
    remove_column :rubygems, :downloads, :integer
  end
end
