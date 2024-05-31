class AddGemPlatformAndGemFullNameToVersions < ActiveRecord::Migration[7.0]
  def change
    change_table(:versions, bulk: true) do |t|
      t.string :gem_platform
      t.string :gem_full_name
    end
  end
end
