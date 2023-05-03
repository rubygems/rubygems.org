FactoryBot.define do
  sequence :email do |n|
    "user#{n}@example.com"
  end

  sequence :handle do |n|
    "handle#{n}"
  end

  sequence :name do |n|
    "RubyGem#{n}"
  end

  sequence :number do |n|
    "0.0.#{n}"
  end

  sequence :url do |n|
    "http://example#{n}.com"
  end
end
