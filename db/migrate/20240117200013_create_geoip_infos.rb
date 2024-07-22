class CreateGeoipInfos < ActiveRecord::Migration[7.1]
  def change
    create_table :geoip_infos do |t|
      t.string :continent_code, limit: 2, null: true
      t.string :country_code, limit: 2, null: true
      t.string :country_code3, limit: 3, null: true
      t.string :country_name, null: true
      t.string :region, null: true
      t.string :city, null: true

      t.timestamps

      t.index %w[continent_code country_code country_code3 country_name region city], unique: true, name: "index_geoip_infos_on_fields"
    end
  end
end
