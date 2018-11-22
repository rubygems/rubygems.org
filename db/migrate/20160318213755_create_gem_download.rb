class CreateGemDownload < ActiveRecord::Migration[4.2]
  def change
    create_table :gem_downloads do |t|
      t.integer :rubygem_id, null: false
      t.integer :version_id, null: false
      t.column :count, :bigint
    end
    add_index :gem_downloads, [:rubygem_id, :version_id], unique: true
  end
end
