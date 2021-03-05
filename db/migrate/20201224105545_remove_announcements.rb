class RemoveAnnouncements < ActiveRecord::Migration[6.0]
  def up
    drop_table :announcements
  end

  def down
    create_table :announcements do |t|
      t.text :body
      t.timestamps
    end
  end
end
