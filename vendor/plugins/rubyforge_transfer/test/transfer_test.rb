
class TransferTest < ActiveSupport::TestCase
  def setup
    @email = "blah@blah.com"
    @password = "secret"
    @sha1 = Digest::SHA1.hexdigest(@password)
    @md5 = Digest::MD5.hexdigest(@password)
  end

  def create_rf_user
    @rf_user = Rubyforger.create(:email => @email, :encrypted_password => @md5)
    @rf_user.password = @password
  end

  def create_gc_user
    @gc_user = User.new(:email => @email)
    @gc_user.password = Time.now.to_s
    @gc_user.email_confirmed = true
    @gc_user.save!
  end

  def test_authenticness
    create_rf_user
    assert(@rf_user.authentic?)
  end

  def test_inauthenticness_due_to_missing_password
    create_rf_user
    @rf_user.password = ""
    assert(!@rf_user.authentic?)
    @rf_user.password = "   "
    assert(!@rf_user.authentic?)
  end

  def test_transfer
    create_rf_user
    create_gc_user
    assert(!User.authenticate(@email, @password))
    @rf_user.password = @password
    assert(@rf_user.transfer_to_gemcutter)
    assert(User.authenticate(@email, @password))
    assert_raises(ActiveRecord::RecordNotFound) { @rf_user.reload }
  end

  def test_transfer_fails_because_pw_is_wrong
    create_rf_user
    create_gc_user
    @rf_user.password = "blah"
    assert(!@rf_user.transfer_to_gemcutter)
  end

  def test_transfer_fails_because_no_such_gemcutter_record
    create_rf_user
    assert_raises(Rubyforger::NoMatchingUser) { @rf_user.transfer_to_gemcutter }
  end
end

