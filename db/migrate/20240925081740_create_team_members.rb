class CreateTeamMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :team_members do |t|
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :team_members, %i[team_id user_id], unique: true
  end
end
