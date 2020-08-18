require "test_helper"

class UserTest < ActiveSupport::TestCase
  def assert_resetting_email_changes(attr_name)
    assert_changed(@user, attr_name) do
      @user.update(email: "some@one.com")
    end
  end

  should have_many(:ownerships).dependent(:destroy)
  should have_many(:rubygems).through(:ownerships)
  should have_many(:subscribed_gems).through(:subscriptions)
  should have_many(:deletions)
  should have_many(:subscriptions).dependent(:destroy)
  should have_many(:web_hooks).dependent(:destroy)

  context "validations" do
    context "handle" do
      should allow_value("CapsLOCK").for(:handle)
      should_not allow_value("1abcde").for(:handle)
      should_not allow_value("abc^%def").for(:handle)
      should_not allow_value("abc\n<script>bad").for(:handle)

      should "be between 2 and 40 characters" do
        user = build(:user, handle: "a")
        refute user.valid?
        assert_contains user.errors[:handle], "is too short (minimum is 2 characters)"

        user.handle = "a" * 41
        refute user.valid?
        assert_contains user.errors[:handle], "is too long (maximum is 40 characters)"

        user.handle = "abcdef"
        user.valid?
        assert_nil user.errors[:handle].first
      end

      should "be invalid when an empty string" do
        user = build(:user, handle: "")
        refute user.valid?
      end

      should "be valid when nil and other users have a nil handle" do
        assert build(:user, handle: nil).valid?
        assert build(:user, handle: nil).valid?
      end

      should "show user id if no handle set" do
        user = build(:user, handle: nil, id: 13)
        assert_equal "#13", user.display_handle

        user.handle = "bills"
        assert_equal "bills", user.display_handle
      end
    end

    context "email" do
      should "be less than 255 characters" do
        user = build(:user, email: ("a" * 255) + "@example.com")
        refute user.valid?
        assert_contains user.errors[:email], "is too long (maximum is 255 characters)"
      end

      should "be valid when it matches URI mail email regex" do
        user = build(:user, email: "mail@example.com")
        assert user.valid?
      end

      should "be invalid when it doesn't match URI mail email regex" do
        user = build(:user, email: "random[a..z]mdhlwqui@163.com")
        refute user.valid?
        assert_contains user.errors[:email], "is invalid"
      end
    end

    context "twitter_username" do
      should validate_length_of(:twitter_username)
      should allow_value("user123_32").for(:twitter_username)
      should_not allow_value("@user").for(:twitter_username)
      should_not allow_value("user 1").for(:twitter_username)
      should_not allow_value("user-1").for(:twitter_username)
      should allow_value("01234567890123456789").for(:twitter_username)
      should_not allow_value("012345678901234567890").for(:twitter_username)
    end

    context "password" do
      should "be between 10 and 200 characters" do
        user = build(:user, password: "%5a&12ed/")
        refute user.valid?
        assert_contains user.errors[:password], "is too short (minimum is 10 characters)"

        user.password = "#{'a8b5d2d451' * 20}a"
        refute user.valid?
        assert_contains user.errors[:password], "is too long (maximum is 200 characters)"

        user.password = "633!cdf7b3426c9%f6dd1a0b62d4ce44c4f544e%"
        user.valid?
        assert_nil user.errors[:password].first
      end

      should "be invalid when an empty string" do
        user = build(:user, password: "")
        refute user.valid?
      end

      should "be invalid when it's found in a data breach" do
        user = build(:user, password: "1234567890")
        refute user.valid?
        assert_contains user.errors[:password], "has previously appeared in a data breach and should not be used"
      end
    end
  end

  context "with a user" do
    setup do
      @user = create(:user)
    end

    should "authenticate with email/password" do
      assert_equal @user, User.authenticate(@user.email, @user.password)
    end

    should "authenticate with handle/password" do
      assert_equal @user, User.authenticate(@user.handle, @user.password)
    end

    should "not authenticate with bad handle, good password" do
      assert_nil User.authenticate("bad", @user.password)
    end

    should "not authenticate with bad email, good password" do
      assert_nil User.authenticate("bad@example.com", @user.password)
    end

    should "not authenticate with good email, bad password" do
      assert_nil User.authenticate(@user.email, "bad")
    end

    should "have email and handle on JSON" do
      json = JSON.parse(@user.to_json)
      hash = { "id" => @user.id, "email" => @user.email, "handle" => @user.handle }
      assert_equal hash, json
    end

    should "have email and handle on XML" do
      xml = Nokogiri.parse(@user.to_xml)
      assert_equal "user", xml.root.name
      assert_equal %w[id handle email], xml.root.children.select(&:element?).map(&:name)
      assert_equal @user.email, xml.at_css("email").content
    end

    should "have email and handle on YAML" do
      yaml = YAML.safe_load(@user.to_yaml)
      hash = { "id" => @user.id, "email" => @user.email, "handle" => @user.handle }
      assert_equal hash, yaml
    end

    should "create api key" do
      assert_not_nil @user.api_key
    end

    should "give user if specified name is user handle or email" do
      assert_not_nil User.find_by_name(@user.handle)
      assert_equal User.find_by_name(@user.handle), User.find_by_name(@user.handle)
    end

    should "give email if handle is not set for name" do
      @user.handle = nil
      assert_nil @user.handle
      assert_equal @user.email, @user.name
    end

    should "give handle if handle is set for name" do
      @user.handle = "qrush"
      @user.save
      assert_equal @user.handle, @user.name
    end

    should "setup a field to toggle showing email" do
      assert_nil @user.hide_email
    end

    should "have a 32 character hexadecimal api key" do
      assert @user.api_key =~ /^[a-f0-9]{32}$/
    end

    should "reset api key" do
      assert_changed(@user, :api_key) do
        @user.reset_api_key!
      end
    end

    should "only return rubygems" do
      my_rubygem = create(:rubygem)
      create(:ownership, user: @user, rubygem: my_rubygem)
      assert_equal [my_rubygem], @user.rubygems
    end

    context "email change" do
      should "reset confirmation token" do
        assert_resetting_email_changes :confirmation_token
      end

      should "store unconfirm email" do
        assert_resetting_email_changes :unconfirmed_email
      end

      should "reset token_expires_at" do
        assert_resetting_email_changes :token_expires_at
      end
    end

    context "with subscribed gems" do
      setup do
        @subscribed_gem   = create(:rubygem)
        @unsubscribed_gem = create(:rubygem)
        create(:subscription, user: @user, rubygem: @subscribed_gem)
      end

      should "only fetch the subscribed gems with #subscribed_gems" do
        assert_contains @user.subscribed_gems, @subscribed_gem
        assert_does_not_contain @user.subscribed_gems, @unsubscribed_gem
      end
    end

    should "have all gems and specific gems for hooks" do
      rubygem = create(:rubygem)
      rubygem_hook = create(:web_hook, user: @user, rubygem: rubygem)
      global_hook  = create(:global_web_hook, user: @user)
      all_hooks = @user.all_hooks
      assert_equal rubygem_hook, all_hooks[rubygem.name].first
      assert_equal global_hook, all_hooks["all gems"].first
    end

    should "have all gems for hooks" do
      global_hook = create(:global_web_hook, user: @user)
      all_hooks = @user.all_hooks
      assert_equal global_hook, all_hooks["all gems"].first
      assert_equal 1, all_hooks.keys.size
    end

    should "have only specific for hooks" do
      rubygem = create(:rubygem)
      rubygem_hook = create(:web_hook, user: @user, rubygem: rubygem)
      all_hooks = @user.all_hooks
      assert_equal rubygem_hook, all_hooks[rubygem.name].first
      assert_equal 1, all_hooks.keys.size
    end

    context "#valid_confirmation_token?" do
      should "return false when email confirmation token has expired" do
        @user.update_attribute(:token_expires_at, 2.minutes.ago)
        refute @user.valid_confirmation_token?
      end

      should "reutrn true when email confirmation token has not expired" do
        two_minutes_in_future = Time.zone.now + 2.minutes
        @user.update_attribute(:token_expires_at, two_minutes_in_future)
        assert @user.valid_confirmation_token?
      end
    end

    context "two factor authentication" do
      should "disable mfa by default" do
        refute @user.mfa_enabled?
      end

      context "when enabled" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
        end

        should "be able to use a recovery code only once" do
          code = @user.mfa_recovery_codes.first
          assert @user.otp_verified?(code)
          refute @user.otp_verified?(code)
        end

        should "be able to verify correct OTP" do
          assert @user.otp_verified?(ROTP::TOTP.new(@user.mfa_seed).now)
        end

        should "return true for mfa status check" do
          assert @user.mfa_enabled?
          refute @user.mfa_disabled?
        end

        should "return true for otp in last interval" do
          last_otp = ROTP::TOTP.new(@user.mfa_seed).at(Time.current - 30)
          assert @user.otp_verified?(last_otp)
        end

        should "return true for otp in next interval" do
          next_otp = ROTP::TOTP.new(@user.mfa_seed).at(Time.current + 30)
          assert @user.otp_verified?(next_otp)
        end

        should "can be blocked" do
          assert_changed(@user, :email, :password, :api_key, :mfa_seed, :remember_token) do
            @user.block!
          end

          assert @user.email.start_with?("security+locked-")
          assert @user.email.end_with?("@rubygems.org")
          assert @user.mfa_recovery_codes.empty?
          assert @user.mfa_disabled?
        end
      end

      context "when disabled" do
        setup do
          @user.disable_mfa!
        end

        should "return false for verifying OTP" do
          refute @user.otp_verified?("")
        end

        should "return false for mfa status check" do
          refute @user.mfa_enabled?
          assert @user.mfa_disabled?
        end
      end
    end
  end

  context ".without_mfa" do
    setup do
      create(:user, handle: "has_mfa", mfa_level: "ui_and_api")
      create(:user, handle: "no_mfa", mfa_level: "disabled")
    end

    should "return only users without mfa" do
      users_without_mfa = User.without_mfa

      assert_equal 1, users_without_mfa.size
      assert_equal "no_mfa", users_without_mfa.first.handle
    end
  end

  context "rubygems" do
    setup do
      @user     = create(:user)
      @rubygems = [2000, 1000, 3000].map do |download|
        create(:rubygem, downloads: download).tap do |rubygem|
          create(:ownership, rubygem: rubygem, user: @user)
          create(:version, rubygem: rubygem)
        end
      end
    end

    should "sort by downloads method" do
      assert_equal @rubygems.values_at(2, 0, 1), @user.rubygems_downloaded
    end

    should "not include gem if all versions have been yanked" do
      @rubygems.first.versions.first.update! indexed: false
      assert_equal 2, @user.rubygems_downloaded.count
    end

    should "total their number of pushed rubygems except yanked gems" do
      @rubygems.first.versions.first.update! indexed: false
      assert_equal @user.total_rubygems_count, 2
    end

    should "not include gems with more than one owner" do
      create(:ownership, rubygem: @rubygems.first)
      assert_equal 2, @user.only_owner_gems.count
    end
  end

  context "yaml" do
    setup do
      @user = create(:user)
    end

    should "return its payload" do
      assert_equal @user.payload, YAML.safe_load(@user.to_yaml)
    end

    should "nest properly" do
      assert_equal [@user.payload], YAML.safe_load([@user].to_yaml)
    end
  end

  context "destroy" do
    setup do
      @user = create(:user)
      @rubygem = create(:rubygem)
      create(:ownership, rubygem: @rubygem, user: @user)
      @version = create(:version, rubygem: @rubygem)
    end

    context "user is only owner of gem" do
      should "record deletion" do
        assert_difference "Deletion.count", 1 do
          @user.destroy
        end
      end
      should "mark rubygem unowned" do
        @user.destroy
        assert @rubygem.unowned?
      end
    end

    context "user has co-owner of gem" do
      setup do
        create(:ownership, rubygem: @rubygem, user: create(:user))
      end

      should "not record deletion" do
        assert_no_difference "Deletion.count" do
          @user.destroy
        end
      end
      should "not mark rubygem unowned" do
        @user.destroy
        refute @rubygem.unowned?
      end
    end
  end

  context "#remember_me!" do
    setup do
      @user = create(:user)
      @user.remember_me!
    end

    should "set remember_token" do
      assert_not_nil @user.remember_token
    end

    should "set expiry of remember_token to two weeks from now" do
      expected_expiry = Gemcutter::REMEMBER_FOR.from_now
      assert_in_delta expected_expiry, @user.remember_token_expires_at, 1.second
    end
  end

  context "#remember_me?" do
    setup { @user = create(:user) }

    should "return false when remember_token_expires_at is not set" do
      refute @user.remember_me?
    end

    should "return false when remember_token has expired" do
      @user.update_attribute(:remember_token_expires_at, 1.second.ago)
      refute @user.remember_me?
    end

    should "return true when remember_token has not expired" do
      @user.update_attribute(:remember_token_expires_at, 1.second.from_now)
      assert @user.remember_me?
    end
  end

  context ".find_by_slug" do
    should "return nil if using a falsy value" do
      refute User.find_by_slug(nil)
    end

    context "foundable" do
      setup { @user = create(:user, handle: "findable") }

      should "return an AR when founded by id" do
        assert_equal User.find_by_slug(@user.id), @user
      end

      should "return an AR when founded by handle" do
        assert_equal User.find_by_slug(@user.handle), @user
      end
    end

    context "not founded" do
      should "return nil when using id" do
        refute User.find_by_slug(-9999)
      end

      should "return nil when not founded by handle" do
        refute User.find_by_slug("notfoundable")
      end
    end
  end
end
