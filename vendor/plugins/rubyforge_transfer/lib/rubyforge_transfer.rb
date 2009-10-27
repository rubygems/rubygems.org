require 'digest/sha1'
module RubyforgeTransfer
  def self.transferee(email, password)
    return false if ::User.find_by_email(email)
    rf_user = Rubyforger.find_by_email(email)
    return false unless rf_user && rf_user.encrypted_password == Digest::MD5.hexdigest(password)

    rf_user.password = password
    rf_user
  end

  def rf_check
    return unless params[:session]
    email, password = params[:session].values_at(:email, :password)
    if rf_user = RubyforgeTransfer.transferee(email, password)
      rf_user.transfer_to_gemcutter
    end
  end
end

