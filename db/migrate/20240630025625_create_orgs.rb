class CreateOrgs < ActiveRecord::Migration[7.1]
  def change
    create_table :orgs do |t|
      t.string :handle
      t.string :name
      t.timestamp :deleted_at

      t.timestamps
    end
  end
end
