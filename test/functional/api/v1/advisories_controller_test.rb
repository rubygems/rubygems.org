require 'test_helper'

class Api::V1::AdvisoriesControllerTest < ActionController::TestCase
  context "with a confirmed user authenticated" do
    setup do
      @user = create(:user)
      @request.env["HTTP_AUTHORIZATION"] = @user.api_key
    end

    context "for a gem SomeGem with a version 0.1.0" do
      setup do
        @rubygem  = create(:rubygem, name: "SomeGem")
        @v1       = create(:version, rubygem: @rubygem, number: "0.1.0", platform: "ruby")
        @message  = "Test Message"
        create(:ownership, user: @user, rubygem: @rubygem)
        RubygemFs.instance.store("gems/#{@v1.full_name}.gem", "")
      end

      context "ON ADVISORY to create for existing gem version" do
        setup do
          post :create, gem_name: @rubygem.to_param, version: @v1.number, message: @message
        end
        should respond_with :success
        should "record the advisory" do
          assert_not_nil Advisory.where(user: @user,
                                        rubygem: @rubygem,
                                        version: @v1).first
        end
      end

      context "and a version 0.1.1" do
        setup do
          @v2 = create(:version, rubygem: @rubygem, number: "0.1.1", platform: "ruby")
        end

        context "ON ADVISORY to create for version 0.1.1" do
          setup do
            post :create, gem_name: @rubygem.to_param, version: @v2.number, message: @message
          end
          should respond_with :success
          should "record the advisory" do
            assert_not_nil Advisory.where(user: @user,
                                          rubygem: @rubygem,
                                          version: @v2).first
          end
        end
      end

      context "and a version 0.1.1 and platform x86-darwin-10" do
        setup do
          @v2 = create(:version, rubygem: @rubygem, number: "0.1.1", platform: "x86-darwin-10")
        end

        context "ON ADVISORY to create for version 0.1.1 and x86-darwin-10" do
          setup do
            post :create, gem_name: @rubygem.to_param, version: @v2.number, platform: @v2.platform, message: @message
          end
          should respond_with :success
          should "show platform in response" do
            assert_equal "Successfully marked gem: SomeGem (0.1.1-x86-darwin-10) as vulnerable.", @response.body
          end
          should "record the advisory" do
            assert_not_nil Advisory.where(
              user: @user,
              rubygem: @rubygem,
              version: @v2,
              platform: @v2.platform
            ).first
          end
        end
      end

      context "ON ADVISORY to create for existing gem with invalid version" do
        setup do
          post :create, gem_name: @rubygem.to_param, version: "0.2.0", message: @message
        end
        should respond_with :not_found
        should "not modify any versions" do
          assert_equal 1, @rubygem.versions.count
          assert_equal 1, @rubygem.versions.indexed.count
        end
        should "not record the advisory" do
          assert_equal 0, @user.advisories.count
        end
      end

      context "ON ADVISORY to create for someone else's gem" do
        setup do
          @other_user = create(:user)
          @request.env["HTTP_AUTHORIZATION"] = @other_user.api_key
          post :create, gem_name: @rubygem.to_param, version: '0.1.0', message: @message
        end
        should respond_with :forbidden
        should "not record the advisory" do
          assert_equal 0, @user.advisories.count
        end
      end

      context "ON ADVISORY to create for an already marked gem" do
        setup do
          Advisory.create!(user: @user, version: @v1, message: @message)
          post :create, gem_name: @rubygem.to_param, version: @v1.number, message: @message
        end
        should respond_with :unprocessable_entity
        should "not re-record the advisory" do
          assert_equal 1, Advisory.where(user: @user,
                                         rubygem: @rubygem,
                                         version: @v1).count
        end
      end
    end
  end
end
