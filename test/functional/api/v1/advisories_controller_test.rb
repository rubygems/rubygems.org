require 'test_helper'
class Api::V1::AdvisoriesControllerTest < ActionController::TestCase
  context "with a confirmed user authenticated" do
    setup do
      @user = create(:user)
      @request.env["HTTP_AUTHORIZATION"] = @user.api_key
    end

    context "for a gem SomeGem with a version 0.1.0" do
      setup do
        @rubygem   = create(:rubygem, name: "SomeGem")
        @v1        = create(:version, rubygem: @rubygem, number: "0.1.0", platform: "ruby")
        @ownership = create(:ownership, user: @user, rubygem: @rubygem)
      end

      context "ON CREATE for own gem" do
        setup do
          get :create, params: { gem_name: @rubygem.to_param, version: @v1.number, cve: '1234-5678', title: 'title', url: 'http://someurl.com' },
                       format: 'json'
        end

        should respond_with :success
        should "Successfully record the advisory " do
          assert_equal "Successfully recorded advisory for gem: SomeGem (0.1.0)", @response.body
          assert_equal 1, @v1.advisories.count
        end
      end

      context "ON CREATE for someone else's gem" do
        setup do
          @ownership.destroy
          get :create, params: { gem_name: @rubygem.to_param, version: @v1.number, cve: '1234-5678', title: 'title', url: 'http://someurl.com' },
                       format: 'json'
        end
        should respond_with 403
        should "does not record the advisory" do
          assert_equal "You do not have correct permission to perform this action.", response.body
          assert_equal 0, @v1.advisories.count
        end
      end
    end
  end
end
