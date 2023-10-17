class ClearanceUpdateUsers < ActiveRecord::Migration[4.2]
  def self.up
    change_table(:users) do |t| # rubocop:disable Rails/BulkChangeTable
      t.string :confirmation_token, limit: 128
      t.string :remember_token, limit: 128
    end

    add_index :users, %i[id confirmation_token]
    add_index :users, :remember_token
  end

  def self.down
    change_table(:users) do |t| # rubocop:disable Rails/BulkChangeTable
      t.remove :confirmation_token, :remember_token
    end
  end
end
