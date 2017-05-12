class ZeroOutVersionDownloads < ActiveRecord::Migration[4.2]
  def self.up
    # Version.update_all(:downloads_count => 0)
  end

  def self.down
    # Version.update_all(:downloads_count => nil)
  end
end
