FactoryGirl.define do
  sequence :url do |n|
    "http://example#{n}.com"
  end

  factory :web_hook do
    rubygem
    url
    user
  end

  factory :global_web_hook, :parent => :web_hook do
    rubygem nil
  end
end
