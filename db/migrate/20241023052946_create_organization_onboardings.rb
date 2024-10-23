class CreateOrganizationOnboardings < ActiveRecord::Migration[7.1]
  def change
    create_table :organization_onboardings do |t|
      t.string :status, null: false
      t.string :organization_name, null: false
      t.string :organization_handle, null: false
      t.text :error, null: true
      t.jsonb :invitees, default: [], null: true
      t.integer :rubygems, array: true, default: [], null: true
      t.datetime :onboarded_at, null: true
      t.integer :onboarded_by, null: true
      t.integer :created_by_id, null: false
      t.integer :onboarded_organization_id, null: true
      t.timestamps
    end
  end
end