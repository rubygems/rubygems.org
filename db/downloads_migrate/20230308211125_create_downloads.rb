class CreateDownloads < ActiveRecord::Migration[7.0]
  def change
    create_table :downloads, id: false do |t|
      t.integer :rubygem_id, null: false
      t.integer :version_id, null: false
      t.integer :downloads, null: false
      t.integer :log_ticket_id, null: true
      t.timestamptz :occurred_at, null: false
    end

    add_index :downloads, [:rubygem_id, :version_id, :occurred_at, :log_ticket_id], unique: true, name: 'idx_downloads_by_version_log_ticket'
    create_hypertable :downloads, :occurred_at, chunk_time_interval: '7 days', partitioning_column: 'rubygem_id'
  end
end
