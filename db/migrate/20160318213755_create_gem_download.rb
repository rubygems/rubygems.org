class CreateGemDownload < ActiveRecord::Migration[4.2]
  def change
    create_table :gem_downloads do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.integer :rubygem_id, null: false
      t.integer :version_id, null: false
      t.column :count, :bigint
    end
    add_index :gem_downloads, %i[rubygem_id version_id], unique: true
  end
end
