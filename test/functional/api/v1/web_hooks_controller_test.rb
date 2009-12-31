require 'test_helper'

class Api::V1::WebHooksControllerTest < ActionController::TestCase
  should_forbid_access_when("creating a web hook") { post :create }
  should_forbid_access_when("listing hooks") { get :index }
  should_forbid_access_when("removing hooks") { delete :remove }

  context "When logged in" do
    setup do
      @url = "http://example.org"
      @user = Factory(:email_confirmed_user)
      @request.env["Authorization"] = @user.api_key
    end

    context "with a rubygem" do
      setup do
        @rubygem = Factory(:rubygem)
        Factory(:version, :rubygem => @rubygem)
      end

      context "with some owned hooks" do
        setup do
          @rubygem_hook = Factory(:web_hook,
                                  :user    => @user,
                                  :rubygem => @rubygem)
          @global_hook  = Factory(:global_web_hook,
                                  :user    => @user)
        end

        context "On GET to index" do
          setup do
            get :index
          end
          should_respond_with :success
          should_respond_with_content_type /json/
        end

        context "On DELETE to remove with owned hook for rubygem" do
          setup do
            delete :remove,
                   :gem_name => @rubygem.name,
                   :url      => @rubygem_hook.url
          end

          should_respond_with :success
          should "say webhook was removed" do
            assert_contain "Successfully removed webhook for #{@rubygem.name} to #{@rubygem_hook.url}"
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

          should_respond_with :success
          should "say webhook was removed" do
            assert_contain "Successfully removed webhook for all gems to #{@global_hook.url}"
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
          @other_user   = Factory(:email_confirmed_user)
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

          should_respond_with :not_found
          should "say webhook was not found" do
            assert_contain "No such webhook exists under your account."
          end
          should "not have actually the webhook" do
            assert_not_nil WebHook.find(@rubygem_hook.id)
          end
        end

        context "On DELETE to remove with global hook" do
          setup do
            delete :remove,
                   :gem_name => WebHook::GLOBAL_PATTERN,
                   :url      => @rubygem_hook.url
          end

          should_respond_with :not_found
          should "say webhook was not found" do
            assert_contain "No such webhook exists under your account."
          end
          should "not have actually the webhook" do
            assert_not_nil WebHook.find(@rubygem_hook.id)
          end
        end
      end

      context "On POST to create hook for a gem that's hosted" do
        setup do
          post :create, :gem_name => @rubygem.name, :url => @url
        end

        should_respond_with :created
        should "say webhook was created" do
          assert_contain "Successfully created webhook for #{@rubygem.name} to #{@url}"
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

        should_respond_with :conflict
        should "be only 1 web hook" do
          assert_equal 1, WebHook.count
          assert_contain "#{@url} has already been registered for #{@rubygem.name}"
        end
      end

      context "On POST to create hook for all gems" do
        setup do
          post :create, :gem_name => WebHook::GLOBAL_PATTERN, :url => @url
        end

        should_respond_with :created
        should "link webhook to current user and no rubygem" do
          assert_equal @user, WebHook.last.user
          assert_nil WebHook.last.rubygem
        end
        should "respond with message that global hook was made" do
          assert_contain "Successfully created webhook for all gems to #{@url}"
        end
      end
    end

    context "On POST to create a hook for a gem that doesn't exist here" do
      setup do
        post :create, :gem_name => "a gem that doesn't exist", :url => @url
      end

      should_respond_with :not_found
      should "say gem is not found" do
        assert_contain "could not be found"
      end
    end

    context "On DELETE to remove a hook for a gem that doesn't exist here" do
      setup do
        delete :remove, :gem_name => "a gem that doesn't exist", :url => @url
      end

      should_respond_with :not_found
      should "say gem is not found" do
        assert_contain "could not be found"
      end
    end

    context "on POST to global web hook that already exists" do
      setup do
        Factory(:global_web_hook, :url => @url, :user => @user)
        post :create, :gem_name => WebHook::GLOBAL_PATTERN, :url => @url
      end

      should_respond_with :conflict
      should "be only 1 web hook" do
         assert_equal 1, WebHook.count
      end
    end
  end
end

