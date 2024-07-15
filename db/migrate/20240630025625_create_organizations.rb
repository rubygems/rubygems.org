class CreateOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations do |t|
      t.string :handle, limit: 40
      t.string :name, limit: 255
      t.timestamp :deleted_at

      t.timestamps

      t.index "lower(handle)", unique: true
    end
  end
end
