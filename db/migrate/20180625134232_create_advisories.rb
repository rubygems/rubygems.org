class CreateAdvisories < ActiveRecord::Migration[5.0]
  def up
    create_table :advisories do |t|
      t.belongs_to :user, index: true
      t.belongs_to :version
      t.string :url
      t.string :title
      t.string :description
      t.string :cve

      t.timestamps null: false
    end
  end

  def down
    drop_table :advisories
  end
end