class AddProcessedCountToLogTicket < ActiveRecord::Migration
  def change
    add_column :log_tickets, :processed_count, :integer
  end
end
