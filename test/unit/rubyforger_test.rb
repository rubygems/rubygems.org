require 'test_helper'

class RubyforgerTest < ActiveSupport::TestCase
  context "with a rubyforge and gemcutter user" do
    setup do
      @email      = "blah@blah.com"
      @password   = "secret"
      @rubyforger = create(:rubyforger, :email              => @email,
                                         :encrypted_password => Digest::MD5.hexdigest(@password))
    end

    should "be authentic" do
      assert @rubyforger.authentic?(@password)
    end

    should "not be authentic with blank password" do
      assert ! @rubyforger.authentic?("")
      assert ! @rubyforger.authentic?("  \n")
    end

    should "not be authentic with wrong password" do
      assert ! @rubyforger.authentic?("trogdor")
    end

    should "transfer over with valid password" do
      user = create(:user, :email => @email)

      assert_equal user, Rubyforger.transfer(@email, @password)
      assert User.authenticate(@email, @password)
      assert ! Rubyforger.exists?(@rubyforger.id)
    end

    should "fail transfer when password is wrong" do
      create(:user, :email => @email)

      assert_nil Rubyforger.transfer(@email, "trogdor")
      assert Rubyforger.exists?(@rubyforger.id)
    end

    should "fail transfer when no gemcutter user exists" do
      assert_nil User.find_by_email(@email)
      assert_nil Rubyforger.transfer(@email, @password)
      assert Rubyforger.exists?(@rubyforger.id)
    end
  end
end

