class CreateAdvisories < ActiveRecord::Migration
  def change
    create_table :advisories do |t|
      t.belongs_to :user, index: true
      t.string :rubygem
      t.string :number
      t.string :message
      t.string :platform

      t.timestamps null: false
    end
  end
end
