FactoryGirl.define do
  factory :rubyforger do
    email
    encrypted_password Digest::SHA1.hexdigest("password")
  end
end
