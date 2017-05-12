class CreateAnnouncements < ActiveRecord::Migration[4.2]
  def self.up
    create_table :announcements do |t|
      t.text :body
      t.timestamps
    end
  end

  def self.down
    drop_table :announcements
  end
end
