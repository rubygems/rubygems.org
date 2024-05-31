FactoryBot.define do
  factory :geoip_info do
    continent_code { "NA" }
    country_code { "US" }
    country_code3 { "USA" }
    sequence(:country_name) { |n| "Country #{n}" }
    region { "NY" }
    city { "Buffalo" }

    trait :usa do
      country_name { "United States of America" }
    end
  end
end
