require 'test_helper'
class Api::V1::AuditsControllerTest < ActionController::TestCase
  context "with a confirmed user authenticated" do
    context "for a gem SomeGem with a version 0.1.0" do
      setup do
        @rubygem   = create(:rubygem, name: "SomeGem")
        @v1        = create(:version, rubygem: @rubygem, number: "0.1.0", platform: "ruby")
        @ownership = create(:ownership, user: @user, rubygem: @rubygem)
      end

      context "ON CHECK for a vulnerable gem version" do
        setup do
          create(:advisory, version: @v1)
          get :check, params: { gem_name: @rubygem.to_param, version: @v1.number }, format: 'json'
        end
        should respond_with :success
        should "display vulnerability" do
          response = JSON.parse(@response.body)

          assert response[@v1.number]['vulnerable']
          refute_equal "This version does not contain any advisories", response[@v1.number]['advisories']
        end
      end

      context "ON CHECK for a non vulnerable gem version" do
        setup do
          get :check, params: { gem_name: @rubygem.to_param, version: @v1.number }, format: 'json'
        end
        should respond_with :success
        should "display vulnerability notification" do
          response = JSON.parse(@response.body)

          assert_not response[@v1.number]['vulnerable']
          assert_equal "This version does not contain any advisories", response[@v1.number]['advisories']
        end
      end
    end

    context "for a gem SomeGem with a version range" do
      setup do
        @rubygem   = create(:rubygem, name: "SomeGem")
        @v1        = create(:version, rubygem: @rubygem, number: "0.1.0")
        @v2        = create(:version, rubygem: @rubygem, number: "0.2.0")
        @v3        = create(:version, rubygem: @rubygem, number: "0.3.0")
        @ownership = create(:ownership, user: @user, rubygem: @rubygem)
        create(:advisory, version: @v1)

        get :check, params: { gem_name: @rubygem.to_param, version_range: "#{@v1.number}..#{@v3.number}" }, format: 'json'
      end

      should respond_with :success
      should "display vulnerability notification" do
        not_vulnerable = "This version does not contain any advisories"
        response_body  = JSON.parse(@response.body)

        assert response_body[@v1.number]['vulnerable']
        refute_equal response_body[@v1.number]['advisories'], not_vulnerable

        assert_not response_body[@v2.number]['vulnerable']
        assert_equal response_body[@v2.number]['advisories'], not_vulnerable

        assert_not response_body[@v3.number]['vulnerable']
        assert_equal response_body[@v3.number]['advisories'], not_vulnerable
      end
    end
  end
end
