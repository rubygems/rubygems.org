class CreateRubyforgers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :rubyforgers do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.string :email
      t.string :encrypted_password, limit: 40
    end
  end

  def self.down
    drop_table :rubyforgers
  end
end
