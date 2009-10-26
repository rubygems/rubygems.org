require 'digest/sha1'
module Rf_Check

  def self.transfer_candidate?(email, password)
    return false if ::User.find_by_email(email)
    return false unless user = Rubyforger.find_by_email(email)
    user.encrypted_password == Digest::MD5.hexdigest(password)
  end

  def self.transfer_user(email, password)
    user = ::User.new(:email => email, :password => password)
    user.email_confirmed = true
    user.password = password
    user.save!
  end


  module Checker
    def rf_check
logger.info("here")
      return unless params[:session]
      email, password = params[:session].values_at(:email, :password)
      if Rf_Check.transfer_candidate?(email, password)
        Rf_Check.transfer_user(email, password)
      end
    end
  end

end

