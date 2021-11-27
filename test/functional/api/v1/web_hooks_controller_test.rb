require "test_helper"

class Api::V1::WebHooksControllerTest < ActionController::TestCase
  def self.should_not_find_it
    should respond_with :not_found
    should "say gem is not found" do
      assert page.has_content?("could not be found")
    end
  end

  context "with incorrect api key" do
    context "no api key" do
      should "forbid access when creating a web hook" do
        rubygem = create(:rubygem)
        post :create, params: { gem_name: rubygem.name, url: "http://example.com" }
        assert_includes @response.body, "Access Denied"
        assert WebHook.count.zero?
      end

      should "forbid access when listing hooks" do
        get :index
        assert_includes @response.body, "Access Denied"
      end

      should "forbid access when firing hooks" do
        post :fire, params: { gem_name: WebHook::GLOBAL_PATTERN, url: "http://example.com" }
        assert_includes @response.body, "Access Denied"
      end

      should "forbid access when removing a web hook" do
        hook = create(:web_hook)
        delete :remove, params: { gem_name: hook.rubygem.name, url: hook.url }
        assert_includes @response.body, "Access Denied"
        assert_equal 1, WebHook.count
      end
    end

    context "no webhook actions scope" do
      setup do
        create(:api_key, key: "12442")
        @request.env["HTTP_AUTHORIZATION"] = "12442"

        get :index
      end

      should respond_with :forbidden
    end
  end

  def self.should_respond_to(format)
    context "with #{format.to_s.upcase}" do
      setup do
        get :index, format: format
      end
      should respond_with :success
      should "be able to parse body" do
        payload = yield(@response.body)
        assert_equal @global_hook.payload, payload["all gems"].first
        assert_equal @rubygem_hook.payload, payload[@rubygem.name].first
      end
    end
  end

  context "with webhook actions api key scope" do
    setup do
      @url = "http://example.org"
      @user = create(:api_key, key: "12342", access_webhooks: true).user

      @request.env["HTTP_AUTHORIZATION"] = "12342"
    end

    context "with the gemcutter gem" do
      setup do
        @gemcutter = create(:rubygem, name: "gemcutter")
        create(:version, rubygem: @gemcutter)
      end

      context "On POST to fire for all gems" do
        setup do
          RestClient.stubs(:post)
          post :fire, params: { gem_name: WebHook::GLOBAL_PATTERN,
                                url: @url }
        end
        should respond_with :success
        should "say successfully deployed" do
          content = "Successfully deployed webhook for #{@gemcutter.name} to #{@url}"
          assert page.has_content?(content)
          assert WebHook.count.zero?
        end
      end

      context "On POST to fire for all gems that fails" do
        setup do
          RestClient.stubs(:post).raises(RestClient::Exception.new)
          post :fire, params: { gem_name: WebHook::GLOBAL_PATTERN,
                                url: @url }
        end
        should respond_with :bad_request
        should "say there was a problem" do
          content = "There was a problem deploying webhook for #{@gemcutter.name} to #{@url}"
          assert page.has_content?(content)
          assert WebHook.count.zero?
        end
      end

      context "On POST to fire with no url" do
        setup do
          post :fire, params: { gem_name: WebHook::GLOBAL_PATTERN }
        end
        should respond_with :bad_request
        should "say url was not provided" do
          content = "URL was not provided"
          assert page.has_content?(content)
        end
      end
    end

    context "with a rubygem" do
      setup do
        @rubygem = create(:rubygem)
        create(:version, rubygem: @rubygem)
      end

      context "On POST to fire for a specific gem" do
        setup do
          RestClient.stubs(:post)
          post :fire, params: { gem_name: @rubygem.name,
                                url: @url }
        end
        should respond_with :success
        should "say successfully deployed" do
          assert page.has_content?("Successfully deployed webhook for #{@rubygem.name} to #{@url}")
          assert WebHook.count.zero?
        end
      end

      context "On POST to fire for a specific gem that fails" do
        setup do
          RestClient.stubs(:post).raises(RestClient::Exception.new)
          post :fire, params: { gem_name: @rubygem.name,
                                url: @url }
        end
        should respond_with :bad_request
        should "say there was a problem" do
          content = "There was a problem deploying webhook for #{@rubygem.name} to #{@url}"
          assert page.has_content?(content)
          assert WebHook.count.zero?
        end
      end

      context "On GET to index with some owned hooks" do
        setup do
          @rubygem_hook = create(:web_hook,
            user: @user,
            rubygem: @rubygem)
          @global_hook = create(:global_web_hook,
            user: @user)
        end

        should_respond_to(:json) do |body|
          JSON.load(body)
        end

        should_respond_to(:yaml) do |body|
          YAML.safe_load(body)
        end

        context "On DELETE to remove with owned hook for rubygem" do
          setup do
            delete :remove, params: { gem_name: @rubygem.name,
                                      url: @rubygem_hook.url }
          end

          should respond_with :success
          should "say webhook was removed" do
            content = "Successfully removed webhook for #{@rubygem.name} to #{@rubygem_hook.url}"
            assert page.has_content?(content)
          end
          should "have actually removed the webhook" do
            assert_raise ActiveRecord::RecordNotFound do
              WebHook.find(@rubygem_hook.id)
            end
          end
        end

        context "On DELETE to remove with owned global hook" do
          setup do
            delete :remove, params: { gem_name: WebHook::GLOBAL_PATTERN,
                                      url: @global_hook.url }
          end

          should respond_with :success
          should "say webhook was removed" do
            content = "Successfully removed webhook for all gems to #{@global_hook.url}"
            assert page.has_content?(content)
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
          @other_user   = create(:user)
          @rubygem_hook = create(:web_hook, user: @other_user, rubygem: @rubygem)
          @global_hook  = create(:global_web_hook, user: @other_user)
        end

        context "On DELETE to remove with owned hook for rubygem" do
          setup do
            delete :remove, params: { gem_name: @rubygem.name, url: @rubygem_hook.url }
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
            delete :remove, params: { gem_name: WebHook::GLOBAL_PATTERN,
                                      url: @rubygem_hook.url }
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
          post :create, params: { gem_name: @rubygem.name, url: @url }
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
          create(:web_hook, rubygem: @rubygem, url: @url, user: @user)
          post :create, params: { gem_name: @rubygem.name, url: @url }
        end

        should respond_with :conflict
        should "be only 1 web hook" do
          assert_equal 1, WebHook.count
          assert page.has_content?("#{@url} has already been registered for #{@rubygem.name}")
        end
      end

      context "On POST to create hook for all gems" do
        setup do
          post :create, params: { gem_name: WebHook::GLOBAL_PATTERN, url: @url }
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
        post :create, params: { gem_name: "a gem that doesn't exist", url: @url }
      end

      should_not_find_it
    end

    context "On DELETE to remove a hook for a gem that doesn't exist here" do
      setup do
        delete :remove, params: { gem_name: "a gem that doesn't exist", url: @url }
      end

      should_not_find_it
    end

    context "on POST to global web hook that already exists" do
      setup do
        create(:global_web_hook, url: @url, user: @user)
        post :create, params: { gem_name: WebHook::GLOBAL_PATTERN, url: @url }
      end

      should respond_with :conflict
      should "be only 1 web hook" do
        assert_equal 1, WebHook.count
      end
    end
  end
end
