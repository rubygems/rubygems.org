class CreateGemDownloadCountIndex < ActiveRecord::Migration
  def change
    add_index :gem_downloads, [:version_id, :rubygem_id, :count]
  end
end
