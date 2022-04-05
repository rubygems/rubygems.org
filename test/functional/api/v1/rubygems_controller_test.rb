require "test_helper"

class Api::V1::RubygemsControllerTest < ActionController::TestCase
  should "route old paths to new controller" do
    get_route = { controller: "api/v1/rubygems", action: "show", id: "rails", format: "json" }
    assert_recognizes(get_route, "/api/v1/gems/rails.json")

    post_route = { controller: "api/v1/rubygems", action: "create" }
    assert_recognizes(post_route, path: "/api/v1/gems", method: :post)
  end

  def self.should_respond_to_show
    should respond_with :success
    should "return a hash" do
      response = yield(@response.body) if block_given?
      assert_not_nil response
      assert_kind_of Hash, response
    end
  end

  def self.should_respond_to(format, &block)
    context "with #{format.to_s.upcase} for a hosted gem" do
      setup do
        @rubygem = create(:rubygem)
        create(:version, rubygem: @rubygem)
        get :show, params: { id: @rubygem.to_param }, format: format
      end

      should_respond_to_show(&block)
    end

    context "with #{format.to_s.upcase} for a hosted gem with a period in its name" do
      setup do
        @rubygem = create(:rubygem, name: "foo.rb")
        create(:version, rubygem: @rubygem)
        get :show, params: { id: @rubygem.to_param }, format: format
      end

      should_respond_to_show(&block)
    end

    context "with #{format.to_s.upcase} for a gem that doesn't match the slug" do
      setup do
        @rubygem = create(:rubygem, name: "ZenTest", slug: "zentest")
        create(:version, rubygem: @rubygem)
        get :show, params: { id: "ZenTest" }, format: format
      end

      should_respond_to_show(&block)
    end
  end

  context "When logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
    end

    context "On GET to show" do
      should_respond_to(:json) do |body|
        JSON.load body
      end

      should_respond_to(:yaml) do |body|
        YAML.safe_load body
      end
    end

    context "On GET to show for a gem that not hosted" do
      setup do
        @rubygem = create(:rubygem)
        assert_predicate @rubygem.versions.count, :zero?
        get :show, params: { id: @rubygem.to_param }, format: "json"
      end

      should respond_with :not_found
      should "say gem could not be found" do
        assert_equal "This rubygem could not be found.", @response.body
      end
    end

    context "On GET to show for a gem that doesn't exist" do
      setup do
        @name = generate(:name)
        refute Rubygem.exists?(name: @name)
        get :show, params: { id: @name }, format: "json"
      end

      should respond_with :not_found
      should "say the rubygem was not found" do
        assert_match(/not be found/, @response.body)
      end
    end

    context "On GET to show for a gem that's yanked" do
      setup do
        @rubygem = create(:rubygem)
        create(:version, rubygem: @rubygem, number: "1.0.0", indexed: false)
        get :show, params: { id: @rubygem.to_param }, format: "json"
      end

      should respond_with :not_found
      should "say gem could not be found" do
        assert_equal "This rubygem could not be found.", @response.body
      end
    end

    context "On GET to show for a gem with dependencies that have missing rubygem" do
      setup do
        @rubygem = create(:rubygem)
        @version = create(:version, rubygem: @rubygem)

        @runtime_dependency = create(:dependency, :runtime, version: @version)
        @runtime_dependency.rubygem.update_column(:name, "foo")
        @missing_dependency = create(:dependency, :runtime, version: @version)
        @missing_dependency.rubygem.update_column(:name, "missing")
        @missing_dependency.update_column(:rubygem_id, nil)

        get :show, params: { id: @rubygem.to_param }, format: "json"
      end

      should respond_with :success
      should "show only dependencies that have rubygem" do
        assert_match(/foo/, @response.body)
        assert_no_match(/missing/, @response.body)
      end
    end
  end

  context "CORS" do
    setup do
      rubygem = create(:rubygem, name: "ZenTest", slug: "zentest")
      create(:version, rubygem: rubygem)
    end

    should "Returns the response CORS headers" do
      @request.env["HTTP_ORIGIN"] = "https://pages.github.com/"
      get :show, params: { id: "ZenTest" }, format: "json"

      assert_equal 200, @response.status
      assert_equal "*", @response.headers["Access-Control-Allow-Origin"]
      assert_equal "GET", @response.headers["Access-Control-Allow-Methods"]
      assert_equal "1728000", @response.headers["Access-Control-Max-Age"]
    end

    should "Send the CORS preflight OPTIONS request" do
      @request.env["HTTP_ORIGIN"] = "https://pages.github.com/"
      process :show, method: :options, params: { id: "ZenTest" }

      assert_equal 200, @response.status
      assert_equal "*", @response.headers["Access-Control-Allow-Origin"]
      assert_equal "GET", @response.headers["Access-Control-Allow-Methods"]
      assert_equal "X-Requested-With, X-Prototype-Version", @response.headers["Access-Control-Allow-Headers"]
      assert_equal "1728000", @response.headers["Access-Control-Max-Age"]
      assert_equal "", @response.body
    end
  end

  def self.should_respond_to(format)
    context "with #{format.to_s.upcase} for a list of gems" do
      setup do
        @mygems = [create(:rubygem, name: "SomeGem"), create(:rubygem, name: "AnotherGem")]
        @mygems.each do |rubygem|
          create(:version, rubygem: rubygem)
          create(:ownership, user: @user, rubygem: rubygem)
        end

        @other_user = create(:user)
        @not_my_rubygem = create(:rubygem, name: "NotMyGem")
        create(:version, rubygem: @not_my_rubygem)
        create(:ownership, user: @other_user, rubygem: @not_my_rubygem)

        get :index, format: format
      end

      should respond_with :success
      should "return a hash" do
        assert_not_nil yield(@response.body)
      end
      should "only return my gems" do
        gem_names = yield(@response.body).map { |rubygem| rubygem["name"] }.sort
        assert_equal %w[AnotherGem SomeGem], gem_names
      end
    end
  end

  context "with index and push rubygem api key scope" do
    setup do
      @api_key = create(:api_key, key: "12345", push_rubygem: true, index_rubygems: true)
      @user = @api_key.user

      @request.env["HTTP_AUTHORIZATION"] = "12345"
    end

    context "On GET to index" do
      should_respond_to :json do |body|
        JSON.load body
      end

      should_respond_to :yaml do |body|
        YAML.safe_load body
      end
    end

    context "When mfa for UI and API is enabled" do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
      end

      context "On post to create for new gem without OTP" do
        setup do
          post :create, body: gem_file.read
        end
        should respond_with :unauthorized
      end

      context "On post to create for new gem with incorrect OTP" do
        setup do
          @request.env["HTTP_OTP"] = (ROTP::TOTP.new(@user.mfa_seed).now.to_i.succ % 1_000_000).to_s
          post :create, body: gem_file.read
        end
        should respond_with :unauthorized
      end

      context "On post to create for new gem with correct OTP" do
        setup do
          @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
          post :create, body: gem_file.read
        end
        should respond_with :success
        should "register new gem" do
          assert_equal 1, Rubygem.count
          assert_equal @user, Rubygem.last.ownerships.first.user
          assert_equal "Successfully registered gem: test (0.0.0)", @response.body
        end
      end
    end

    context "When mfa for UI and gem signin is enabled" do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_gem_signin)
      end

      context "Api key has mfa enabled" do
        setup do
          @api_key.mfa = true
          @api_key.save!
          post :create, body: gem_file.read
        end
        should respond_with :unauthorized
      end

      context "On POST to create for new gem" do
        setup do
          post :create, body: gem_file.read
        end
        should respond_with :success
        should "register new gem" do
          assert_equal 1, Rubygem.count
          assert_equal @user, Rubygem.last.versions.first.pusher
          assert_equal "Successfully registered gem: test (0.0.0)", @response.body
        end
        should "add user as confirmed owner" do
          ownership = Rubygem.last.ownerships.first

          assert_equal @user, ownership.user
          assert_predicate ownership, :confirmed?
        end
      end
    end

    context "On POST to create for new gem" do
      setup do
        post :create, body: gem_file.read
      end
      should respond_with :success
      should "register new gem" do
        assert_equal 1, Rubygem.count
        assert_equal @user, Rubygem.last.versions.first.pusher
        assert_equal "Successfully registered gem: test (0.0.0)", @response.body
      end
      should "add user as confirmed owner" do
        ownership = Rubygem.last.ownerships.first

        assert_equal @user, ownership.user
        assert_predicate ownership, :confirmed?
      end
    end

    context "On POST to create for existing gem" do
      context "with confirmed ownership" do
        setup do
          create(:global_web_hook, user: @user, url: "http://example.org")
          rubygem = create(:rubygem, name: "test")
          create(:ownership, rubygem: rubygem, user: @user)
          create(:version, rubygem: rubygem, number: "0.0.0", updated_at: 1.year.ago, created_at: 1.year.ago)
        end
        should "respond_with success" do
          post :create, body: gem_file("test-1.0.0.gem").read
          assert_response :success
        end
        should "register new version" do
          post :create, body: gem_file("test-1.0.0.gem").read
          assert_equal @user, Rubygem.last.ownerships.first.user
          assert_equal 1, Rubygem.last.ownerships.count
          assert_equal 2, Rubygem.last.versions.count
          assert_equal "Successfully registered gem: test (1.0.0)", @response.body
        end
        should "enqueue jobs" do
          assert_difference "Delayed::Job.count", 8 do
            post :create, body: gem_file("test-1.0.0.gem").read
          end
        end
      end

      context "with unconfirmed ownership" do
        setup do
          create(:global_web_hook, user: @user, url: "http://example.org")
          rubygem = create(:rubygem, name: "test")
          create(:ownership, :unconfirmed, rubygem: rubygem, user: @user)
          create(:version, rubygem: rubygem, number: "0.0.0", updated_at: 1.year.ago, created_at: 1.year.ago)
          assert_difference "Delayed::Job.count", 0 do
            post :create, body: gem_file("test-1.0.0.gem").read
          end
        end
        should respond_with :forbidden
      end
    end

    context "On POST to create for a repush" do
      setup do
        rubygem = create(:rubygem, name: "test")
        create(:ownership, rubygem: rubygem, user: @user)

        @date = 1.year.ago
        @version = create(:version,
                          rubygem: rubygem,
                          number: "0.0.0",
                          updated_at: @date,
                          created_at: @date,
                          summary: "Freewill",
                          authors: ["Geddy Lee"],
                          built_at: @date)

        post :create, body: gem_file.read
      end
      should respond_with :conflict
      should "not register new version" do
        version = Rubygem.last.reload.versions.most_recent
        assert_equal @date.to_formatted_s(:db), version.built_at.to_formatted_s(:db), "(date)"
        assert_equal "Freewill", version.summary, "(summary)"
        assert_equal "Geddy Lee", version.authors, "(authors)"
      end
    end

    context "On POST to create with bad gem" do
      setup do
        post :create, body: "really bad gem"
      end
      should respond_with :unprocessable_entity
      should "not register gem" do
        assert_predicate Rubygem.count, :zero?
        assert_match(/RubyGems\.org cannot process this gem/, @response.body)
      end
    end

    context "On POST to create with an underscore or dash variant of an existing gem" do
      setup do
        existing = create(:rubygem, name: "t_es-t", downloads: 3002)
        existing.versions.create(number: "1.0.0", platform: "ruby")
        post :create, body: gem_file("test-1.0.0.gem").read
      end

      should respond_with :forbidden
      should "not register new gem" do
        assert_equal 1, Rubygem.count
        assert_equal "There was a problem saving your gem: Name 'test' is too similar to an existing gem named 't_es-t'", @response.body
      end
    end

    context "On POST to create for someone else's gem" do
      setup do
        @other_user = create(:user)
        @rubygem = create(:rubygem, name: "test", number: "0.0.0", owners: [@other_user])
        create(:global_web_hook, user: @user, url: "http://example.org")

        post :create, body: gem_file("test-1.0.0.gem").read
      end
      should respond_with 403
      should "not allow new version to be saved" do
        assert_equal 1, @rubygem.ownerships.size
        assert_equal @other_user, @rubygem.ownerships.first.user
        assert_equal 1, @rubygem.versions.size
        assert_equal 0, Delayed::Job.count
        assert_includes @response.body, "You do not have permission to push to this gem."
      end
    end

    context "On POST to create with reserved gem name" do
      setup do
        post :create, body: gem_file("rubygems-0.1.0.gem").read
      end
      should respond_with 403
      should "not register gem" do
        assert_predicate Rubygem.count, :zero?
        assert_match(/There was a problem saving your gem: Name 'rubygems' is a reserved gem name./, @response.body)
      end
    end

    context "with elasticsearch down" do
      setup do
        rubygem = create(:rubygem, name: "test")
        create(:ownership,
               rubygem: rubygem,
               user: @user)
        create(:version,
               rubygem: rubygem,
               number: "0.0.0",
               updated_at: 1.year.ago,
               created_at: 1.year.ago)
      end
      should "POST to create for existing gem should not fail" do
        requires_toxiproxy
        Toxiproxy[:elasticsearch].down do
          post :create, body: gem_file("test-1.0.0.gem").read
          assert_response :success
          assert_equal @user, Rubygem.last.ownerships.first.user
          assert_equal 1, Rubygem.last.ownerships.count
          assert_equal 2, Rubygem.last.versions.count
          assert_equal "Successfully registered gem: test (1.0.0)", @response.body
        end
      end
    end
  end

  context "push to create with mfa required" do
    setup do
      @user = create(:api_key, key: "12345", push_rubygem: true).user
      @request.env["HTTP_AUTHORIZATION"] = "12345"
    end

    context "new gem without MFA enabled" do
      setup do
        post :create, body: gem_file("mfa-required-1.0.0.gem").read
      end
      should respond_with :forbidden
    end

    context "new gem with correct OTP" do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
        @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
        post :create, body: gem_file("mfa-required-1.0.0.gem").read
      end
      should respond_with :success
      should "register new gem" do
        assert_equal 1, Rubygem.count
        assert_equal @user, Rubygem.last.ownerships.first.user
        assert_equal "Successfully registered gem: mfa_required (1.0.0)", @response.body
      end
    end

    context "for existing gem" do
      setup do
        rubygem = create(:rubygem, name: "mfa_required")
        create(:ownership, rubygem: rubygem, user: @user)
        create(:version, rubygem: rubygem, number: "0.0.0")
      end

      context "by user without mfa" do
        setup do
          post :create, body: gem_file("mfa-required-1.0.0.gem").read
        end

        should respond_with :forbidden
      end

      context "by user with mfa" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
          @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
          post :create, body: gem_file("mfa-required-1.0.0.gem").read
        end

        should respond_with :success
        should "register new version" do
          assert_equal 1, Rubygem.count
          assert_equal 2, Rubygem.last.versions.count
        end
      end
    end

    context "rubygems_mfa_required already enabled" do
      setup do
        @rubygem = create(:rubygem, name: "test")
        create(:ownership, rubygem: @rubygem, user: @user)
        create(:version, rubygem: @rubygem, number: "0.0.0", metadata: { "rubygems_mfa_required" => "true" })
      end

      context "by user without mfa" do
        setup do
          post :create, body: gem_file("test-1.0.0.gem").read
        end

        should respond_with :forbidden

        should "show error message" do
          assert_equal "Rubygem requires owners to enable MFA. You must enable MFA before pushing new version.", @response.body
        end
      end

      context "by user with mfa" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
          @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
          post :create, body: gem_file("test-1.0.0.gem").read
        end

        should respond_with :success
        should "register new version" do
          assert_equal 1, Rubygem.count
          assert_equal 2, Rubygem.last.versions.count
        end
        should "disable mfa requirement" do
          refute_predicate @rubygem, :mfa_required?
        end
      end
    end
  end

  context "push with api key with gem scoped" do
    context "to a gem with ownership removed" do
      setup do
        ownership = create(:ownership, user: create(:user), rubygem: create(:rubygem, name: "test-gem123"))
        @api_key = create(:api_key, key: "12343", user: ownership.user, ownership: ownership, push_rubygem: true)
        ownership.destroy!
        @request.env["HTTP_AUTHORIZATION"] = "12343"

        post :create, body: gem_file("test-1.0.0.gem").read
      end

      should respond_with :forbidden
      should "#render_soft_deleted_api_key and display an error" do
        assert_equal "An invalid API key cannot be used. Please delete it and create a new one.", @response.body
      end
    end

    context "to a different gem" do
      setup do
        ownership = create(:ownership, user: create(:user), rubygem: create(:rubygem, name: "test-gem"))
        create(:api_key, key: "12343", user: ownership.user, ownership: ownership, push_rubygem: true)
        @request.env["HTTP_AUTHORIZATION"] = "12343"

        post :create, body: gem_file("test-1.0.0.gem").read
      end

      should respond_with :forbidden
      should "say gem scope is invalid" do
        assert_equal "This API key cannot perform the specified action on this gem.", @response.body
      end
    end

    context "to the gem being pushed" do
      setup do
        ownership = create(:ownership, user: create(:user), rubygem: create(:rubygem, name: "test"))
        create(:api_key, key: "12343", user: ownership.user, ownership: ownership, push_rubygem: true)
        @request.env["HTTP_AUTHORIZATION"] = "12343"

        post :create, body: gem_file("test-1.0.0.gem").read
      end

      should respond_with :ok
    end
  end

  context "with incorrect api key" do
    context "on GET to index with JSON for a list of gems without api key" do
      setup do
        get :index, format: "json"
      end
      should "deny access" do
        assert_response 401
        assert_equal "Access Denied. Please sign up for an account at https://rubygems.org",
                     @response.body
      end
    end

    context "on GET to index without index rubygem scope" do
      setup do
        create(:api_key, key: "12345", index_rubygems: false, push_rubygem: true)
        @request.env["HTTP_AUTHORIZATION"] = "12345"
        get :index, format: :json
      end

      should respond_with :forbidden
    end

    context "on POST to create without push rubygem scope" do
      setup do
        create(:api_key, key: "12343")
        @request.env["HTTP_AUTHORIZATION"] = "12343"

        post :create, body: gem_file("test-1.0.0.gem").read
      end
      should respond_with :forbidden
    end
  end

  %w[json xml yaml].each do |format|
    context "on GET to show for an unknown gem with #{format} format" do
      setup do
        get :show, params: { id: "rials" }, format: format
      end

      should "return a 404" do
        assert_response :not_found
      end

      should "say gem could not be found" do
        assert_equal "This rubygem could not be found.", @response.body
      end
    end
  end

  context "on GET to reverse_dependencies" do
    setup do
      @dependency = create(:rubygem)
      @gem_one = create(:rubygem)
      @gem_two = create(:rubygem)
      @gem_three = create(:rubygem)
      version_one = create(:version, rubygem: @gem_one)
      version_two = create(:version, rubygem: @gem_two)
      version_three = create(:version, rubygem: @gem_three)

      create(:dependency, :runtime, version: version_one, rubygem: @dependency)
      create(:dependency, :development, version: version_two, rubygem: @dependency)
      create(:dependency, :runtime, version: version_three, rubygem: @dependency)
    end

    should "return names of reverse dependencies" do
      get :reverse_dependencies, params: { id: @dependency.to_param }, format: "json"
      gems = JSON.load(@response.body)

      assert_equal 3, gems.size

      assert_includes gems, @gem_one.name
      assert_includes gems, @gem_two.name
      assert_includes gems, @gem_three.name
    end

    context "with only=development" do
      should "only return names of reverse development dependencies" do
        get :reverse_dependencies,
            params: { id: @dependency.to_param,
                      only: "development",
                      format: "json" }

        gems = JSON.load(@response.body)

        assert_equal 1, gems.size

        assert_includes gems, @gem_two.name
      end
    end

    context "with only=runtime" do
      should "only return names of reverse development dependencies" do
        get :reverse_dependencies,
            params: { id: @dependency.to_param,
                      only: "runtime",
                      format: "json" }

        gems = JSON.load(@response.body)

        assert_equal 2, gems.size

        assert_includes gems, @gem_one.name
        assert_includes gems, @gem_three.name
      end
    end
  end
end
