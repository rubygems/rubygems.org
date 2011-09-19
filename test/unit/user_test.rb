require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  should have_many(:ownerships)
  should have_many(:rubygems).through(:ownerships)
  should have_many(:subscribed_gems).through(:subscriptions)
  should have_many(:subscriptions)
  should have_many(:web_hooks)

  context "validations" do
    context "handle" do
      should allow_value("CapsLOCK").for(:handle)
      should_not allow_value("1abcde").for(:handle)
      should_not allow_value("abc^%def").for(:handle)
      should_not allow_value("abc\n<script>bad").for(:handle)

      should "be between 3 and 15 characters" do
        user = FactoryGirl.build(:user, :handle => "a")
        assert ! user.valid?
        assert_equal "is too short (minimum is 3 characters)", user.errors[:handle].first

        user.handle = "a" * 16
        assert ! user.valid?
        assert_equal "is too long (maximum is 15 characters)", user.errors[:handle].first

        user.handle = "abcdef"
        user.valid?
        assert_nil user.errors[:handle].first
      end

      should "be invalid when an empty string" do
        user = FactoryGirl.build(:user, :handle => "")
        assert ! user.valid?
      end

      should "be valid when nil and other users have a nil handle" do
        assert FactoryGirl.build(:user, :handle => nil).valid?
        assert FactoryGirl.build(:user, :handle => nil).valid?
      end

      should "show user id if no handle set" do
        user = FactoryGirl.build(:user, :handle => nil, :id => 13)
        assert_equal "#13", user.display_handle

        user.handle = "bills"
        assert_equal "bills", user.display_handle
      end
    end
  end

  context "with a user" do
    setup do
      @user = Factory(:user)
    end

    should "authenticate with email/password" do
      assert_equal @user, User.authenticate(@user.email, @user.password)
    end

    should "authenticate with handle/password" do
      assert_equal @user, User.authenticate(@user.handle, @user.password)
    end

    should "transfer over rubyforge user" do
      @rubyforger = Factory(:rubyforger, :email => @user.email, :encrypted_password => Digest::MD5.hexdigest(@user.password))
      assert_equal @user, User.authenticate(@user.email, @user.password)
      assert ! Rubyforger.exists?(@rubyforger.id)
    end

    should "not transfer over rubyforge user if password is wrong" do
      @rubyforger = Factory(:rubyforger, :email => @user.email, :encrypted_password => Digest::MD5.hexdigest(@user.password))
      assert_nil User.authenticate(@user.email, "trogdor")
      assert Rubyforger.exists?(@rubyforger.id)
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

    should "only have email when boiling down to JSON" do
      json = JSON.parse(@user.to_json)
      hash = {"email" => @user.email}
      assert_equal hash, json
    end

    should "only have email when boiling down to XML" do
      xml = Nokogiri.parse(@user.to_xml)
      assert_equal "user", xml.root.name
      assert_equal %w[email], xml.root.children.select(&:element?).map(&:name)
      assert_equal @user.email, xml.at_css("email").content
    end

    should "only have email when boiling down to YAML" do
      yaml = YAML.load(@user.to_yaml)
      hash = {'email' => @user.email}
      assert_equal hash, yaml
    end

    should "create api key" do
      assert_not_nil @user.api_key
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

    should "have a 32 character hexadecimal api key" do
      assert @user.api_key =~ /^[a-f0-9]{32}$/
    end

    should "reset api key" do
      assert_changed(@user, :api_key) do
        @user.reset_api_key!
      end
    end

    should "only return rubygems" do
      my_rubygem = Factory(:rubygem)
      Factory(:ownership, :user => @user, :rubygem => my_rubygem)
      assert_equal [my_rubygem], @user.rubygems
    end

    context "with subscribed gems" do
      setup do
        @subscribed_gem   = Factory(:rubygem)
        @unsubscribed_gem = Factory(:rubygem)
        Factory(:subscription, :user => @user, :rubygem => @subscribed_gem)
      end

      should "only fetch the subscribed gems with #subscribed_gems" do
        assert_contains         @user.subscribed_gems, @subscribed_gem
        assert_does_not_contain @user.subscribed_gems, @unsubscribed_gem
      end
    end

    should "have all gems and specific gems for hooks" do
      rubygem = Factory(:rubygem)
      rubygem_hook = Factory(:web_hook, :user => @user, :rubygem => rubygem)
      global_hook  = Factory(:global_web_hook, :user => @user)
      all_hooks = @user.all_hooks
      assert_equal rubygem_hook, all_hooks[rubygem.name].first
      assert_equal global_hook, all_hooks["all gems"].first
    end

    should "have all gems for hooks" do
      global_hook  = Factory(:global_web_hook, :user => @user)
      all_hooks = @user.all_hooks
      assert_equal global_hook, all_hooks["all gems"].first
      assert_equal 1, all_hooks.keys.size
    end

    should "have only specific for hooks" do
      rubygem = Factory(:rubygem)
      rubygem_hook = Factory(:web_hook, :user => @user, :rubygem => rubygem)
      all_hooks = @user.all_hooks
      assert_equal rubygem_hook, all_hooks[rubygem.name].first
      assert_equal 1, all_hooks.keys.size
    end
  end

  context "downloads" do
    setup do
      @user      = Factory(:user)
      @rubygem   = Factory(:rubygem)
      @ownership = Factory(:ownership, :rubygem => @rubygem, :user => @user)
      @version   = Factory(:version, :rubygem => @rubygem)

      Download.incr(@version.rubygem.name, @version.full_name)
      Download.rollover
      2.times { Download.incr(@version.rubygem.name, @version.full_name) }
    end

    should "sum up downloads for this user" do
      assert_equal 2, @user.today_downloads_count
      assert_equal 3, @user.total_downloads_count
    end
  end

  context "rubygems" do
    setup do
      @user     = Factory(:user)
      @rubygem1 = Factory(:rubygem, :downloads => 100)
      @rubygem2 = Factory(:rubygem, :downloads => 200)
      @rubygem3 = Factory(:rubygem, :downloads => 300)

      [@rubygem1, @rubygem2, @rubygem3].each do |rubygem|
        Factory(:ownership, :rubygem => rubygem, :user => @user)
      end
    end

    should "limit by default" do
      assert_equal [@rubygem3, @rubygem2, @rubygem1],
        @user.rubygems_downloaded
    end

    should "limit by 2" do
      assert_equal [@rubygem3, @rubygem2],
        @user.rubygems_downloaded(2)
    end

    should "skip the first gem and limit to 2" do
      assert_equal [@rubygem2, @rubygem1],
        @user.rubygems_downloaded(2, 1)
    end

    should "skip no gems if limit is nil" do
      assert_equal [@rubygem3, @rubygem2, @rubygem1],
        @user.rubygems_downloaded(nil, 0)
    end
  end
end
