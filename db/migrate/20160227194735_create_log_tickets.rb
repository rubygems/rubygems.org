class CreateLogTickets < ActiveRecord::Migration[4.2]
  def change
    create_table :log_tickets do |t|
      t.string :key
      t.string :directory
      t.integer :backend, default: 0
      t.string :status

      t.timestamps null: false
    end

    add_index :log_tickets, [:directory, :key], unique: true
  end
end
