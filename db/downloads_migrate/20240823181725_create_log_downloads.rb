# Mimic LogTicket table to store the log files but for the downloads database
# It will be used to store the log files to be processed during the migration
class CreateLogDownloads < ActiveRecord::Migration[7.1]
  def change
    create_table :log_downloads do |t|
      t.string :key
      t.string :directory
      t.integer :backend
      t.string :status, default: "pending"
      t.integer :processed_count, default: 0
      t.timestamps
    end

    add_index :log_downloads, [:key, :directory], unique: true
  end
end