class CreateRubyforgers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :rubyforgers do |t|
      t.string :email
      t.string :encrypted_password, limit: 40
    end
  end

  def self.down
    drop_table :rubyforgers
  end
end
