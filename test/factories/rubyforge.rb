Factory.define :rubyforger do |rf|
  rf.email                 { Factory.next :email }
  rf.encrypted_password    { Digest::SHA1.hexdigest("password") }
end

