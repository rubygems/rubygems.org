FactoryBot.define do
  factory :linkset do
    rubygem
    home { "http://example.com" }
    wiki { "http://example.com" }
    docs { "http://example.com" }
    mail { "http://example.com" }
    code { "http://example.com" }
    bugs { "http://example.com" }
  end
end
