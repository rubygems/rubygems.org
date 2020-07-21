class CreateOwnershipTransfer < ActiveRecord::Migration[6.0]
  def change
    create_table :ownership_calls do |t|
      t.belongs_to :rubygem
      t.belongs_to :user
      t.text :note
      t.boolean :status, default: true, null: false
      t.timestamps
    end

    create_table :ownership_requests do |t|
      t.belongs_to :rubygem
      t.belongs_to :ownership_call
      t.belongs_to :user
      t.text :note
      t.integer :status, limit: 1, default: 0, null: false
      t.integer :approver_id
      t.timestamps
    end
  end
end
