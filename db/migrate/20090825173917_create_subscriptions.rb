class CreateSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.references :rubygem
      t.references :user
      t.timestamps
    end
  end

  def self.down
    drop_table :subscriptions
  end
end
