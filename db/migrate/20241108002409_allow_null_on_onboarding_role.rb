class AllowNullOnOnboardingRole < ActiveRecord::Migration[7.2]
  def change
    change_column_null :organization_onboarding_invites, :role, true
  end
end
