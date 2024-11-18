class AddOrganizationOnboardingInvites < ActiveRecord::Migration[7.2]
  def change
    create_table :organization_onboarding_invites do |t|
      t.references :organization_onboarding, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: true

      t.timestamps
    end
  end
end
