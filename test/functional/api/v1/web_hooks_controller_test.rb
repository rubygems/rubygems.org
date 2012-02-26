require 'test_helper'

class Api::V1::WebHooksControllerTest < ActionController::TestCase
  def self.should_not_find_it
    should respond_with :not_found
    should "say gem is not found" do
      assert page.has_content?("could not be found")
    end
  end

  context "When not logged in" do
    should "forbid access when creating a web hook" do
      rubygem = Factory(:rubygem)
      post :create, :gem_name => rubygem.name, :url => "http://example.com"
      assert @response.body =~ /Access Denied/
      assert WebHook.count.zero?
    end

    should "forbid access when listing hooks" do
      get :index
      assert @response.body =~ /Access Denied/
    end

    should "forbid access when firing hooks" do
      post :fire, :gem_name => WebHook::GLOBAL_PATTERN, :url => "http://example.com"
      assert @response.body =~ /Access Denied/
    end

    should "forbid access when removing a web hook" do
      hook = Factory(:web_hook)
      delete :remove, :gem_name => hook.rubygem.name, :url => hook.url
      assert @response.body =~ /Access Denied/
      assert_equal 1, WebHook.count
    end
  end

  def self.should_respond_to(format)
    context "with #{format.to_s.upcase}" do
      setup do
        get :index, :format => format
      end
      should respond_with :success
      should "be able to parse body" do
        payload = yield(@response.body)
        assert_equal @global_hook.payload, payload["all gems"].first
        assert_equal @rubygem_hook.payload, payload[@rubygem.name].first
      end
    end
  end

  context "When logged in" do
    setup do
      @url = "http://example.org"
      @user = Factory(:user)
      @request.env["Authorization"] = @user.api_key
    end

    context "with the gemcutter gem" do
      setup do
        @gemcutter = Factory(:rubygem, :name => "gemcutter")
        Factory(:version, :rubygem => @gemcutter)
      end

      context "On POST to fire for all gems" do
        setup do
          stub_request(:post, @url)
          post :fire, :gem_name => WebHook::GLOBAL_PATTERN,
                      :url      => @url
        end
        should respond_with :success
        should "say successfully deployed" do
          assert page.has_content?("Successfully deployed webhook for #{@gemcutter.name} to #{@url}")
          assert WebHook.count.zero?
        end
      end

      context "On POST to fire for all gems that fails" do
        setup do
          stub_request(:post, @url).to_return(:status => 500)
          post :fire, :gem_name => WebHook::GLOBAL_PATTERN,
                      :url      => @url
        end
        should respond_with :bad_request
        should "say successfully deployed" do
          assert page.has_content?("There was a problem deploying webhook for #{@gemcutter.name} to #{@url}")
          assert WebHook.count.zero?
        end
      end
    end

    context "with a rubygem" do
      setup do
        @rubygem = Factory(:rubygem)
        Factory(:version, :rubygem => @rubygem)
      end

      context "On POST to fire for a specific gem" do
        setup do
          stub_request(:post, @url)
          post :fire, :gem_name => @rubygem.name,
                      :url      => @url
        end
        should respond_with :success
        should "say successfully deployed" do
          assert page.has_content?("Successfully deployed webhook for #{@rubygem.name} to #{@url}")
          assert WebHook.count.zero?
        end
      end

      context "On POST to fire for a specific gem that fails" do
        setup do
          stub_request(:post, @url).to_return(:status => 500)
          post :fire, :gem_name => @rubygem.name,
                      :url      => @url
        end
        should respond_with :bad_request
        should "say there was a problem" do
          assert page.has_content?("There was a problem deploying webhook for #{@rubygem.name} to #{@url}")
          assert WebHook.count.zero?
        end
      end

      context "On GET to index with some owned hooks" do
        setup do
          @rubygem_hook = Factory(:web_hook,
                                  :user    => @user,
                                  :rubygem => @rubygem)
          @global_hook  = Factory(:global_web_hook,
                                  :user    => @user)
        end

        should_respond_to(:json) do |body|
          MultiJson.decode body
        end

        should_respond_to(:yaml) do |body|
          YAML.load body
        end

        should_respond_to(:xml) do |body|
          children = Nokogiri.parse(body).root.children
          Hash.from_xml(children[1].to_xml).update(
            'all gems' => Hash.from_xml(children[3].to_xml).delete('all_gems')
          )
        end

        context "On DELETE to remove with owned hook for rubygem" do
          setup do
            delete :remove,
                   :gem_name => @rubygem.name,
                   :url      => @rubygem_hook.url
          end

          should respond_with :success
          should "say webhook was removed" do
            assert page.has_content?("Successfully removed webhook for #{@rubygem.name} to #{@rubygem_hook.url}")
          end
          should "have actually removed the webhook" do
            assert_raise ActiveRecord::RecordNotFound do
              WebHook.find(@rubygem_hook.id)
            end
          end
        end

        context "On DELETE to remove with owned global hook" do
          setup do
            delete :remove,
                   :gem_name => WebHook::GLOBAL_PATTERN,
                   :url      => @global_hook.url
          end

          should respond_with :success
          should "say webhook was removed" do
            assert page.has_content?("Successfully removed webhook for all gems to #{@global_hook.url}")
          end
          should "have actually removed the webhook" do
            assert_raise ActiveRecord::RecordNotFound do
              WebHook.find(@global_hook.id)
            end
          end
        end
      end

      context "with some unowned hooks" do
        setup do
          @other_user   = Factory(:user)
          @rubygem_hook = Factory(:web_hook,
                                  :user    => @other_user,
                                  :rubygem => @rubygem)
          @global_hook  = Factory(:global_web_hook,
                                  :user    => @other_user)
        end

        context "On DELETE to remove with owned hook for rubygem" do
          setup do
            delete :remove,
                   :gem_name => @rubygem.name,
                   :url      => @rubygem_hook.url
          end

          should respond_with :not_found
          should "say webhook was not found" do
            assert page.has_content?("No such webhook exists under your account.")
          end
          should "not delete the webhook" do
            assert_not_nil WebHook.find(@rubygem_hook.id)
          end
        end

        context "On DELETE to remove with global hook" do
          setup do
            delete :remove,
                   :gem_name => WebHook::GLOBAL_PATTERN,
                   :url      => @rubygem_hook.url
          end

          should respond_with :not_found
          should "say webhook was not found" do
            assert page.has_content?("No such webhook exists under your account.")
          end
          should "not delete the webhook" do
            assert_not_nil WebHook.find(@rubygem_hook.id)
          end
        end
      end

      context "On POST to create hook for a gem that's hosted" do
        setup do
          post :create, :gem_name => @rubygem.name, :url => @url
        end

        should respond_with :created
        should "say webhook was created" do
          assert page.has_content?("Successfully created webhook for #{@rubygem.name} to #{@url}")
        end
        should "link webhook to current user and rubygem" do
          assert_equal @user, WebHook.last.user
          assert_equal @rubygem, WebHook.last.rubygem
        end
      end

      context "on POST to create hook that already exists" do
        setup do
          Factory(:web_hook, :rubygem => @rubygem, :url => @url, :user => @user)
          post :create, :gem_name => @rubygem.name, :url => @url
        end

        should respond_with :conflict
        should "be only 1 web hook" do
          assert_equal 1, WebHook.count
          assert page.has_content?("#{@url} has already been registered for #{@rubygem.name}")
        end
      end

      context "On POST to create hook for all gems" do
        setup do
          post :create, :gem_name => WebHook::GLOBAL_PATTERN, :url => @url
        end

        should respond_with :created
        should "link webhook to current user and no rubygem" do
          assert_equal @user, WebHook.last.user
          assert_nil WebHook.last.rubygem
        end
        should "respond with message that global hook was made" do
          assert page.has_content?("Successfully created webhook for all gems to #{@url}")
        end
      end
    end

    context "On POST to create a hook for a gem that doesn't exist here" do
      setup do
        post :create, :gem_name => "a gem that doesn't exist", :url => @url
      end

      should_not_find_it
    end

    context "On DELETE to remove a hook for a gem that doesn't exist here" do
      setup do
        delete :remove, :gem_name => "a gem that doesn't exist", :url => @url
      end

      should_not_find_it
    end

    context "on POST to global web hook that already exists" do
      setup do
        Factory(:global_web_hook, :url => @url, :user => @user)
        post :create, :gem_name => WebHook::GLOBAL_PATTERN, :url => @url
      end

      should respond_with :conflict
      should "be only 1 web hook" do
        assert_equal 1, WebHook.count
      end
    end
  end
end

