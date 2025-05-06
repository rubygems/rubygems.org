class CreateRubygemTransferInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :rubygem_transfer_invites do |t|
      t.belongs_to :rubygem_transfer, null: false, foreign_key: { on_delete: :cascade }
      t.belongs_to :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :role
      t.timestamps
    end
  end
end
