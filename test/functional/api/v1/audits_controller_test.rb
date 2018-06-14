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
          @h = get :check, params: { gem_name: @rubygem.to_param, version: @v1.number }
        end
        should respond_with :success
        should "display vulnerability" do
          assert_equal "#{@v1.number}: This version contains vulnerabilities", response.body
        end
      end

      context "ON CHECK for a non vulnerable gem version" do
        setup do
          get :check, params: { gem_name: @rubygem.to_param, version: @v1.number }
        end
        should respond_with :success
        should "display vulnerability notification" do
          assert_equal "#{@v1.number}: This version does not contain any vulnerabilities", @response.body
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
        get :check, params: { gem_name: @rubygem.to_param, version_range: "#{@v1.number}..#{@v3.number}" }
      end

      should respond_with :success
      should "display vulnerability notification" do
        expected_v3 = "0.3.0: This version does not contain any vulnerabilities"
        expected_v2 = "0.2.0: This version does not contain any vulnerabilities"
        expected_v1 = "0.1.0: This version contains vulnerabilities"
        assert @response.body.include? expected_v1
        assert @response.body.include? expected_v2
        assert @response.body.include? expected_v3
      end
    end
  end
end
