class ClearanceUpdateUsers < ActiveRecord::Migration
  def self.up
    change_table(:users) do |t|
      t.string :confirmation_token, limit: 128
      t.string :remember_token, limit: 128
    end

    add_index :users, [:id, :confirmation_token]
    add_index :users, :remember_token
  end

  def self.down
    change_table(:users) do |t|
      t.remove :confirmation_token,:remember_token
    end
  end
end
