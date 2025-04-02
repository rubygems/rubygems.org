FactoryBot.define do
  factory :log_ticket do
    sequence(:key) { "key-#{it}" }
    sequence(:directory) { "directory-#{it}" }
    status { :pending }
  end
end
