class Rubyforger < ActiveRecord::Base
  attr_accessor :password

  def authentic?
    return false if password.blank?
    encrypted_password == Digest::MD5.hexdigest(password)
  end

  def transfer_to_gemcutter
    user = ::User.new(:email => email, :password => password)
    user.email_confirmed = true
    user.password = password
    user.save!
    self.delete
  end
end
