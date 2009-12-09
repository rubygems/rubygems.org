Factory.sequence :email do |n|
  "user#{n}@example.com"
end

Factory.define :rubyforger do |rf|
  rf.email                 { Factory.next :email }
  rf.encrypted_password    { Digest::SHA1.hexdigest("password") }
end

