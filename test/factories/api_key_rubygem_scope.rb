FactoryBot.define do
  factory :api_key_rubygem_scope do
    ownership
    api_key { create(:api_key, key: SecureRandom.hex(24)) }
  end
end
