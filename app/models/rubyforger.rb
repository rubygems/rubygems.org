class Rubyforger < ActiveRecord::Base
  
  def authentic?(password)
    password.present? && encrypted_password == Digest::MD5.hexdigest(password)
  end

  def user
    @user ||= User.find_by_email(email)
  end

  def transferable?(password)
    user if authentic?(password) && user
  end

  def self.transfer(email, password)
    if rubyforger = Rubyforger.find_by_email(email)
      if user = rubyforger.transferable?(password)
        user.update_password(password)
        rubyforger.destroy
        user
      end
    end
  end
end
