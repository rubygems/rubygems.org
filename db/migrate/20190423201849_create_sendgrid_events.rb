class CreateSendgridEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :sendgrid_events do |t|
      t.string :sendgrid_id, null: false
      t.string :email
      t.string :event_type
      t.datetime :occurred_at
      t.jsonb :payload, null: false
      t.string :status, null: false

      t.timestamps
    end

    add_index :sendgrid_events, :sendgrid_id, unique: true
    add_index :sendgrid_events, :email
  end
end
