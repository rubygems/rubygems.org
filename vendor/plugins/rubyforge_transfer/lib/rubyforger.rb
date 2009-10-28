class Rubyforger < ActiveRecord::Base

  class NoMatchingUser < RuntimeError
  end

  attr_accessor :password

  def authentic?
    return false if password.blank?
    encrypted_password == Digest::MD5.hexdigest(password)
  end

  def transfer_to_gemcutter
    return false unless authentic?
    gc_user = User.find_by_email(self.email)
    raise NoMatchingUser unless gc_user
    gc_user.password = self.password
    gc_user.email_confirmed = true
    gc_user.save!
    self.delete
  end
end
