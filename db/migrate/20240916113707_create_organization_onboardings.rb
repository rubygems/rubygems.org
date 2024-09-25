class CreateOrganizationOnboardings < ActiveRecord::Migration[7.1]
  def change
    create_table :organization_onboardings do |t|
      t.string :status, null: false
      t.string :title, null: false
      t.string :slug, null: false
      t.text :error, null: true
      t.integer :invites, array: true, default: []
      t.integer :rubygems, array: true, default: []
      t.datetime :onboarded_at, null: true
      t.integer :onboarded_by, null: true
      t.integer :created_by, null: false
      t.timestamps
    end
  end
end
