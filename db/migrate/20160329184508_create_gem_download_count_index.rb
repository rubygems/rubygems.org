class CreateGemDownloadCountIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :gem_downloads, [:version_id, :rubygem_id, :count]
  end
end
