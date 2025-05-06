class CreateRubygemTransfers < ActiveRecord::Migration[8.0]
  def change
    create_table :rubygem_transfers do |t|
      t.string :status, null: false, default: "pending"
      t.string :transferable_type, null: false
      t.string :transferable_id, null: false
      t.belongs_to :created_by, null: false, foreign_key: false
      t.belongs_to :rubygem, null: false, foreign_key: false
      t.datetime :completed_at
      t.jsonb :users, null: false, default: {}
      t.timestamps
    end
  end
end
