class CreateIpAddresses < ActiveRecord::Migration[7.0]
  def change
    create_table :ip_addresses do |t|
      t.inet :ip_address, null: false, index: { unique: true }
      t.text :hashed_ip_address, null: false, index: { unique: true }, limit: 44
      t.belongs_to :geoip_info, null: true, foreign_key: true

      t.timestamps
    end
  end
end
