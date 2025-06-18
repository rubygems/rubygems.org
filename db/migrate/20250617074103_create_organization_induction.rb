class CreateOrganizationInduction < ActiveRecord::Migration[8.0]
  def change
    create_table :organization_inductions do |t|
      t.references :user, null: false, foreign_key: { to_table: :users }
      t.references :principal, polymorphic: true, null: false
      t.string :role, null: true

      t.timestamps
    end

    add_index :organization_inductions, %i[principal_type principal_id]
  end
end
