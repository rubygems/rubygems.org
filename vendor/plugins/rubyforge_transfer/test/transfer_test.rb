
class TransferTest < ActiveSupport::TestCase
  def setup
    @email = "blah@blah.com"
    @password = "secret"
    @sha1 = Digest::SHA1.hexdigest(@password)
    @md5 = Digest::MD5.hexdigest(@password)
  end

  def test_authenticness
    r = Rubyforger.create(:email => @email, :encrypted_password => @md5)
    r.password = @password
    assert(r.authentic?)
  end

  def test_inauthenticness_due_to_missing_password
    r = Rubyforger.create(:email => @email, :encrypted_password => @md5)
    assert(!r.authentic?)
  end
    
  def test_transferee
    r = Rubyforger.create(:email => @email, :encrypted_password => @md5)
    assert(RubyforgeTransfer.transferee(@email, @password))
  end 

  def test_transfer
    assert(!User.authenticate(@email, @password))
    r = Rubyforger.create(:email => @email, :encrypted_password => @md5)
    r.password = @password
    assert(r.transfer_to_gemcutter)
    assert(User.authenticate(@email, @password))
  end
end
