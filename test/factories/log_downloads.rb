FactoryBot.define do
  factory :log_download do
    sequence(:key) { "key-#{_1}" }
    sequence(:directory) { "directory-#{_1}" }
    status { :pending }
    backend { 0 }
  end
end
