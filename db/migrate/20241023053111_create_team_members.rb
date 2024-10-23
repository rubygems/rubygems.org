class CreateTeamMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :team_members do |t|
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.index %i[team_id user_id], unique: true
      t.timestamps
    end
  end
end
