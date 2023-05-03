FactoryBot.define do
  factory :sendgrid_event do
    sequence(:sendgrid_id) { |n| "TestSendgridId#{n}" }
    status { "pending" }
    payload { {} }
  end
end
