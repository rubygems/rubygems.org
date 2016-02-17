require 'test_helper'

class Api::V1::RubygemsControllerTest < ActionController::TestCase
  should "route old paths to new controller" do
    get_route = { controller: 'api/v1/rubygems', action: 'show', id: "rails", format: "json" }
    assert_recognizes(get_route, '/api/v1/gems/rails.json')

    post_route = { controller: 'api/v1/rubygems', action: 'create' }
    assert_recognizes(post_route, path: '/api/v1/gems', method: :post)
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
        get :show, id: @rubygem.to_param, format: format
      end

      should_respond_to_show(&block)
    end

    context "with #{format.to_s.upcase} for a hosted gem with a period in its name" do
      setup do
        @rubygem = create(:rubygem, name: 'foo.rb')
        create(:version, rubygem: @rubygem)
        get :show, id: @rubygem.to_param, format: format
      end

      should_respond_to_show(&block)
    end

    context "with #{format.to_s.upcase} for a gem that doesn't match the slug" do
      setup do
        @rubygem = create(:rubygem, name: "ZenTest", slug: "zentest")
        create(:version, rubygem: @rubygem)
        get :show, id: "ZenTest", format: format
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
        YAML.load body
      end
    end

    context "On GET to show for a gem that not hosted" do
      setup do
        @rubygem = create(:rubygem)
        assert @rubygem.versions.count.zero?
        get :show, id: @rubygem.to_param, format: "json"
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
        get :show, id: @name, format: "json"
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
        get :show, id: @rubygem.to_param, format: "json"
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
        @runtime_dependency.rubygem.update_column(:name, 'foo')
        @missing_dependency = create(:dependency, :runtime, version: @version)
        @missing_dependency.rubygem.update_column(:name, 'missing')
        @missing_dependency.update_column(:rubygem_id, nil)

        get :show, id: @rubygem.to_param, format: "json"
      end

      should respond_with :success
      should "show only dependencies that have rubygem" do
        assert_match(/foo/, @response.body)
        assert_no_match(/missing/, @response.body)
      end
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
        gem_names = yield(@response.body).map { |rubygem| rubygem['name'] }.sort
        assert_equal %w(AnotherGem SomeGem), gem_names
      end
    end
  end

  context "with a confirmed user authenticated" do
    setup do
      @user = create(:user)
      @request.env["HTTP_AUTHORIZATION"] = @user.api_key
    end

    context "On GET to index" do
      should_respond_to :json do |body|
        JSON.load body
      end

      should_respond_to :yaml do |body|
        YAML.load body
      end
    end

    context "On POST to create for new gem" do
      setup do
        @request.env["RAW_POST_DATA"] = gem_file.read
        post :create
      end
      should respond_with :success
      should "register new gem" do
        assert_equal 1, Rubygem.count
        assert_equal @user, Rubygem.last.ownerships.first.user
        assert_equal "Successfully registered gem: test (0.0.0)", @response.body
      end
    end

    context "On POST to create for existing gem" do
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
        @request.env["RAW_POST_DATA"] = gem_file("test-1.0.0.gem").read
        assert_difference 'Delayed::Job.count', 2 do
          post :create
        end
      end
      should respond_with :success
      should "register new version" do
        assert_equal @user, Rubygem.last.ownerships.first.user
        assert_equal 1, Rubygem.last.ownerships.count
        assert_equal 2, Rubygem.last.versions.count
        assert_equal "Successfully registered gem: test (1.0.0)", @response.body
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

        @request.env["RAW_POST_DATA"] = gem_file.read
        post :create
      end
      should respond_with :conflict
      should "not register new version" do
        version = Rubygem.last.reload.versions.most_recent
        assert_equal @date.to_s(:db), version.built_at.to_s(:db), "(date)"
        assert_equal "Freewill", version.summary, '(summary)'
        assert_equal "Geddy Lee", version.authors, '(authors)'
      end
    end

    context "On POST to create with bad gem" do
      setup do
        @request.env["RAW_POST_DATA"] = "really bad gem"
        post :create
      end
      should respond_with :unprocessable_entity
      should "not register gem" do
        assert Rubygem.count.zero?
        assert_match(/RubyGems\.org cannot process this gem/, @response.body)
      end
    end

    context "On POST to create for someone else's gem" do
      setup do
        @other_user = create(:user)
        @rubygem = create(:rubygem, name: "test", number: "0.0.0", owners: [@other_user])

        @request.env["RAW_POST_DATA"] = gem_file("test-1.0.0.gem").read
        post :create
      end
      should respond_with 403
      should "not allow new version to be saved" do
        assert_equal 1, @rubygem.ownerships.size
        assert_equal @other_user, @rubygem.ownerships.first.user
        assert_equal 1, @rubygem.versions.size
        assert_equal "You do not have permission to push to this gem.", @response.body
      end
    end

    context "On POST to create with reserved gem name" do
      setup do
        @request.env["RAW_POST_DATA"] = gem_file("openssl-0.1.0.gem").read
        post :create
      end
      should respond_with 403
      should "not register gem" do
        assert Rubygem.count.zero?
        assert_match(/There was a problem saving your gem: Name 'openssl' is a reserved gem name./, @response.body)
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
          @request.env["RAW_POST_DATA"] = gem_file("test-1.0.0.gem").read
          post :create
          assert_response :success
          assert_equal @user, Rubygem.last.ownerships.first.user
          assert_equal 1, Rubygem.last.ownerships.count
          assert_equal 2, Rubygem.last.versions.count
          assert_equal "Successfully registered gem: test (1.0.0)", @response.body
        end
      end
    end
  end

  context "No signed in-user" do
    context "On GET to index with JSON for a list of gems" do
      setup do
        get :index, format: "json"
      end
      should "deny access" do
        assert_response 401
        assert_equal "Access Denied. Please sign up for an account at https://rubygems.org",
          @response.body
      end
    end

    %w(json xml yaml).each do |format|
      context "on GET to show for an unknown gem with #{format} format" do
        setup do
          get :show, id: "rials", format: format
        end

        should "return a 404" do
          assert_response :not_found
        end

        should "say gem could not be found" do
          assert_equal "This rubygem could not be found.", @response.body
        end
      end
    end
  end

  context "on GET to reverse_dependencies" do
    setup do
      @dep_rubygem = create(:rubygem)
      @gem_one = create(:rubygem)
      @gem_two = create(:rubygem)
      @gem_three = create(:rubygem)
      @gem_four = create(:rubygem)
      @gem_five = create(:rubygem)
      @version_one_latest  = create(:version, rubygem: @gem_one, number: '0.2')
      @version_one_earlier = create(:version, rubygem: @gem_one, number: '0.1')
      @version_two_latest  = create(:version, rubygem: @gem_two, number: '1.0')
      @version_two_earlier = create(:version, rubygem: @gem_two, number: '0.5')
      @version_three = create(:version, rubygem: @gem_three, number: '1.7')
      @version_four = create(:version, rubygem: @gem_four, number: '3.9')
      @version_five = create(:version, rubygem: @gem_five, number: '4.5')

      @version_one_latest.dependencies << create(:dependency,
        version: @version_one_latest,
        rubygem: @dep_rubygem)
      @version_two_earlier.dependencies << create(:dependency,
        version: @version_two_earlier,
        rubygem: @dep_rubygem)
      @version_three.dependencies << create(:dependency,
        version: @version_three,
        rubygem: @dep_rubygem)
      @version_five.dependencies << create(:dependency, :development,
        version: @version_five,
        rubygem: @dep_rubygem)
    end

    should "return names of reverse dependencies" do
      get :reverse_dependencies, id: @dep_rubygem.to_param, format: "json"
      gems = JSON.load(@response.body)

      assert_equal 4, gems.size

      assert gems.include?(@gem_one.name)
      assert gems.include?(@gem_two.name)
      assert gems.include?(@gem_three.name)
      refute gems.include?(@gem_four.name)
    end

    context "with only=development" do
      should "only return names of reverse development dependencies" do
        get :reverse_dependencies,
          id: @dep_rubygem.to_param,
          only: "development",
          format: "json"

        gems = JSON.load(@response.body)

        assert_equal 1, gems.size

        assert gems.include?(@gem_five.name)
      end
    end

    context "with only=runtime" do
      should "only return names of reverse development dependencies" do
        get :reverse_dependencies,
          id: @dep_rubygem.to_param,
          only: "runtime",
          format: "json"

        gems = JSON.load(@response.body)

        assert_equal 3, gems.size

        assert gems.include?(@gem_one.name)
        assert gems.include?(@gem_two.name)
        assert gems.include?(@gem_three.name)
      end
    end
  end
end
