require 'digest/sha1'

module RubyforgeTransfer
  def rf_check
    return unless creds = params[:session]
    return unless rf_user = Rubyforger.find_by_email(creds[:email])

    rf_user.password = creds[:password]
    rf_user.transfer_to_gem_cutter
  end
end
