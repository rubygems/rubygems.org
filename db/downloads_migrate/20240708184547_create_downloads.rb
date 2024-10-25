class CreateDownloads < ActiveRecord::Migration[7.1]

  disable_ddl_transaction!

  def self.up
    self.down if Download.table_exists?

    hypertable_options = {
      time_column: 'created_at',
      chunk_time_interval: '1 day',
      compress_segmentby: 'gem_name, gem_version',
      compress_orderby: 'created_at DESC',
      compression_interval: '7 days'
    }

    create_table(:downloads, id: false, hypertable: hypertable_options) do |t|
      t.timestamptz :created_at, null: false
      t.text :gem_name, :gem_version, null: false
      t.jsonb :payload
    end

    Download.create_continuous_aggregates
  end
  def self.down
    Download.drop_continuous_aggregates

    drop_table(:downloads, force: :cascade, if_exists: true) if Download.table_exists?
  end
end
