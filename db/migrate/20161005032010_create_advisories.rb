class CreateAdvisories < ActiveRecord::Migration
  def up
    create_table :advisories do |t|
      t.belongs_to :user, index: true
      t.belongs_to :rubygem
      t.belongs_to :version
      t.string :message
      t.string :platform

      t.timestamps null: false
    end
  end

  def down
    drop_table :advisories
  end
end
