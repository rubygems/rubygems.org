FactoryBot.define do
  factory :geoip_info do
    skip_create

    continent_code { "NA" }
    country_code { "US" }
    country_code3 { "USA" }
    country_name { "United States of America" }
    region { "NY" }
    city { "Buffalo" }
  end
end
