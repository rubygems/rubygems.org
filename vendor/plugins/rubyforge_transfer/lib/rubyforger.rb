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

  def self.transferee(email, password)
    return false if ::User.find_by_email(email)
    return false unless rf_user = Rubyforger.find_by_email(email)
    rf_user.password = password
    return false unless rf_user.authentic?
    rf_user
  end
end
