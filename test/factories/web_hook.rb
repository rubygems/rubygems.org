FactoryBot.define do
  factory :web_hook do
    rubygem
    url
    user

    factory :global_web_hook do
      rubygem { nil }
    end
  end
end
