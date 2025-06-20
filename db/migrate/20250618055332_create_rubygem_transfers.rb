class CreateRubygemTransfers < ActiveRecord::Migration[8.0]
  def change
    create_table :rubygem_transfers do |t|
      t.string :status, null: false, default: "pending"
      t.references :organization, null: true, foreign_key: { to_table: :organizations }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :rubygem, null: false, foreign_key: { to_table: :rubygems }
      t.datetime :completed_at, null: true
      t.text :error, null: true
      t.timestamps
    end
  end
end
