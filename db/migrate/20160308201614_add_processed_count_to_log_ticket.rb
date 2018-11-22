class AddProcessedCountToLogTicket < ActiveRecord::Migration[4.2]
  def change
    add_column :log_tickets, :processed_count, :integer
  end
end
