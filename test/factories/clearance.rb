FactoryGirl.define do
  sequence :email do |n|
    "user#{n}@example.com"
  end

  sequence :handle do |n|
    "handle#{n}"
  end

  factory :user do
    email
    handle
    password              "password"
    password_confirmation "password"
  end

  factory :email_confirmed_user, :parent => :user do
    email_confirmed true
  end
end
