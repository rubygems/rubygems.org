class AddGemPlatformAndGemFullNameToVersions < ActiveRecord::Migration[7.0]
  def change
    add_column :versions, :gem_platform, :string
    add_column :versions, :gem_full_name, :string
  end
end
