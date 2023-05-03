FactoryBot.define do
  factory :log_ticket do
    sequence(:key) { "key-#{_1}" }
    sequence(:directory) { "directory-#{_1}" }
    status { :pending }
  end
end
