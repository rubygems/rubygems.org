require 'test_helper'
class Api::V1::AuditsControllerTest < ActionController::TestCase
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
        RubygemFs.instance.store("gems/#{@v1.full_name}.gem", "")
      end

      context "ON CHECK for a vulnerable gem version" do
        setup do
          @v1.update(vulnerable: true)
          @h = get :check, params: { gem_name: @rubygem.to_param, version: @v1.number }, format: 'json'
        end
        should respond_with :success
        should "display vulnerability" do
          assert_equal [], JSON.parse(@response.body)
        end
      end

      context "ON CHECK for a non vulnerable gem version" do
        setup do
          get :check, params: { gem_name: @rubygem.to_param, version: @v1.number }, format: 'json'
        end
        should respond_with :success
        should "display vulnerability notification" do
          assert_equal "This version does not contain any vulnerabilities", @response.body
        end
      end
    end

    context "for a gem SomeGem with a version range" do
      setup do
        @rubygem   = create(:rubygem, name: "SomeGem")
        @v1        = create(:version, rubygem: @rubygem, number: "0.1.0", platform: "ruby", vulnerable: true)
        @v2        = create(:version, rubygem: @rubygem, number: "0.2.0", platform: "ruby")
        @v3        = create(:version, rubygem: @rubygem, number: "0.3.0", platform: "ruby")
        @v4        = create(:version, rubygem: @rubygem, number: "0.4.0", platform: "ruby")
        @ownership = create(:ownership, user: @user, rubygem: @rubygem)
        RubygemFs.instance.store("gems/#{@v1.full_name}.gem", "")
        get :check, params: { gem_name: @rubygem.to_param, version_range: "#{@v1.number}..#{@v3.number}" }, format: 'json'
      end

      should respond_with :success
      should "display vulnerability notification" do
        not_vulnerable = "This version does not contain any vulnerabilities"
        response_body  = JSON.parse(@response.body)

        assert response_body['0.3.0'].include? not_vulnerable
        assert response_body['0.2.0'].include? not_vulnerable

        assert_equal [], response_body['0.1.0']
      end
    end
  end
end
