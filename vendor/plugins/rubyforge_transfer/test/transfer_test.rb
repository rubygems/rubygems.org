
class TransferTest < ActiveSupport::TestCase
  def setup
    @email = "blah@blah.com"
    @password = "secret"
    @sha1 = Digest::SHA1.hexdigest(@password)
    @md5 = Digest::MD5.hexdigest(@password)
  end

  def create_rf_user
    @rf_user = Rubyforger.create(:email => @email, :encrypted_password => @md5)
  end

  def test_authenticness
    create_rf_user
    @rf_user.password = @password
    assert(@rf_user.authentic?)
  end

  def test_inauthenticness_due_to_missing_password
    create_rf_user
    assert(!@rf_user.authentic?)
  end
    
  def test_transferee
    create_rf_user
    assert(Rubyforger.transferee(@email, @password))
  end 

  def test_transfer
    create_rf_user
    assert(!User.authenticate(@email, @password))
    @rf_user.password = @password
    assert(@rf_user.transfer_to_gemcutter)
    assert(User.authenticate(@email, @password))
  end
end
