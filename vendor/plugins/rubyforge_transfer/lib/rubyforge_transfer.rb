require 'digest/sha1'

module RubyforgeTransfer
  def rf_check
    return unless creds = params[:session]
    if rf_user = Rubyforger.transferee(creds[:email], creds[:password])
      rf_user.transfer_to_gemcutter
    end
  end
end
