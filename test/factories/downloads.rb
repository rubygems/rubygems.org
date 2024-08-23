FactoryBot.define do
  factory :download do
    gem_name { "example" }
    gem_version { "0.0.1" }
    payload { { env: { bundler: "2.5.9", rubygems: "3.3.25", ruby: "3.1.0" } } }
    created_at { Time.now }
  end
end
