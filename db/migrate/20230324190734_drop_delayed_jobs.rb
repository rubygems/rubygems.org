class DropDelayedJobs < ActiveRecord::Migration[7.0]
  def up
    drop_table :delayed_jobs
  end

  def down
    create_table "delayed_jobs", id: :serial, force: :cascade do |t|
      t.integer "priority", default: 0
      t.integer "attempts", default: 0
      t.text "handler"
      t.text "last_error"
      t.datetime "run_at", precision: nil
      t.datetime "locked_at", precision: nil
      t.datetime "failed_at", precision: nil
      t.string "locked_by"
      t.datetime "created_at", precision: nil
      t.datetime "updated_at", precision: nil
      t.string "queue"
    end
  end
end
