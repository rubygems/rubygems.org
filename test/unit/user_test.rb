require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def assert_resetting_email_changes(attr_name)
    assert_changed(@user, attr_name) do
      @user.update_attributes(email: 'some@one.com')
    end
  end

  should have_many(:ownerships)
  should have_many(:rubygems).through(:ownerships)
  should have_many(:subscribed_gems).through(:subscriptions)
  should have_many(:deletions)
  should have_many(:subscriptions)
  should have_many(:web_hooks)

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

    context 'twitter_username' do
      should validate_length_of(:twitter_username)
      should allow_value("user123_32").for(:twitter_username)
      should_not allow_value("@user").for(:twitter_username)
      should_not allow_value("user 1").for(:twitter_username)
      should_not allow_value("user-1").for(:twitter_username)
      should allow_value("01234567890123456789").for(:twitter_username)
      should_not allow_value("012345678901234567890").for(:twitter_username)
    end

    context 'password' do
      should 'be between 10 and 200 characters' do
        user = build(:user, password: 'a' * 9)
        refute user.valid?
        assert_contains user.errors[:password], 'is too short (minimum is 10 characters)'

        user.password = 'a' * 201
        refute user.valid?
        assert_contains user.errors[:password], 'is too long (maximum is 200 characters)'

        user.password = 'secretpassword'
        user.valid?
        assert_nil user.errors[:password].first
      end

      should 'be invalid when an empty string' do
        user = build(:user, password: '')
        refute user.valid?
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
      hash = { "id" => @user.id, "email" => @user.email, 'handle' => @user.handle }
      assert_equal hash, json
    end

    should "have email and handle on XML" do
      xml = Nokogiri.parse(@user.to_xml)
      assert_equal "user", xml.root.name
      assert_equal %w(id handle email), xml.root.children.select(&:element?).map(&:name)
      assert_equal @user.email, xml.at_css("email").content
    end

    should "have email and handle on YAML" do
      yaml = YAML.load(@user.to_yaml)
      hash = { 'id' => @user.id, 'email' => @user.email, 'handle' => @user.handle }
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

      should "unconfirm email" do
        assert_resetting_email_changes :unconfirmed?
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

    context '#valid_confirmation_token?' do
      should 'return false when email confirmation token has expired' do
        @user.update_attribute(:token_expires_at, 2.minutes.ago)
        refute @user.valid_confirmation_token?
      end

      should 'reutrn true when email confirmation token has not expired' do
        two_minutes_in_future = Time.zone.now + 2.minutes
        @user.update_attribute(:token_expires_at, two_minutes_in_future)
        assert @user.valid_confirmation_token?
      end
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
  end

  context "yaml" do
    setup do
      @user = create(:user)
    end

    should "return its payload" do
      assert_equal @user.payload, YAML.load(@user.to_yaml)
    end

    should "nest properly" do
      assert_equal [@user.payload], YAML.load([@user].to_yaml)
    end
  end
end
