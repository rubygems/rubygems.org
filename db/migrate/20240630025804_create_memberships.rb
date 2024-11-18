class CreateMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :memberships do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :organization, null: false, foreign_key: true
      t.timestamp :confirmed_at, default: nil

      t.timestamps
      t.index %i[user_id organization_id], unique: true
    end
  end
end
