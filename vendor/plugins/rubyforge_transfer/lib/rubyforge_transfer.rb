require 'digest/sha1'

module RubyforgeTransfer
  def self.transferee(email, password)
    return false if ::User.find_by_email(email)
    return false unless rf_user = Rubyforger.find_by_email(email)
    rf_user.password = password
    return false unless rf_user.authentic?
    rf_user
  end

  def rf_check
    return unless creds = params[:session]
    if rf_user = RubyforgeTransfer.transferee(creds[:email], creds[:password])
      rf_user.transfer_to_gemcutter
    end
  end
end
