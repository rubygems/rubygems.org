class RemoveRubygemsDownloads < ActiveRecord::Migration[4.2]
  def change
    remove_column :rubygems, :downloads, :integer
  end
end
