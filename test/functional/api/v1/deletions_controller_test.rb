require 'test_helper'

class Api::V1::DeletionsControllerTest < ActionController::TestCase
  context "with a confirmed user authenticated" do
    setup do
      @user = create(:user)
      @request.env["HTTP_AUTHORIZATION"] = @user.api_key
    end

    context "for a gem SomeGem with a version 0.1.0" do
      setup do
        @rubygem  = create(:rubygem, name: "SomeGem")
        @v1       = create(:version, rubygem: @rubygem, number: "0.1.0", platform: "ruby")
        create(:ownership, user: @user, rubygem: @rubygem)
        RubygemFs.instance.store("gems/#{@v1.full_name}.gem", "")
      end

      context "ON DELETE for a gem with greater than 15000 downloads" do
        setup do
          @v1.gem_download.count = 15_000
          @v1.gem_download.save
          delete :create, gem_name: @rubygem.to_param, version: @v1.number
        end
        should respond_with :bad_request
        should "not modify any versions" do
          assert_equal 1, @rubygem.versions.count
          assert_equal 1, @rubygem.versions.indexed.count
        end
        should "not record the deletion" do
          assert_equal 0, @user.deletions.count
        end
      end

      context "ON DELETE to create for existing gem version" do
        setup do
          delete :create, gem_name: @rubygem.to_param, version: @v1.number
        end
        should respond_with :success
        should "keep the gem, deindex, keep owner" do
          assert_equal 1, @rubygem.versions.count
          assert @rubygem.versions.indexed.count.zero?
        end
        should "record the deletion" do
          assert_not_nil Deletion.where(user: @user,
                                        rubygem: @rubygem.name,
                                        number: @v1.number).first
        end
      end

      context "and a version 0.1.1" do
        setup do
          @v2 = create(:version, rubygem: @rubygem, number: "0.1.1", platform: "ruby")
        end

        context "ON DELETE to create for version 0.1.1" do
          setup do
            delete :create, gem_name: @rubygem.to_param, version: @v2.number
          end
          should respond_with :success
          should "keep the gem, deindex it, and keep the owners" do
            assert_equal 2, @rubygem.versions.count
            assert_equal 1, @rubygem.versions.indexed.count
            assert_equal 1, @rubygem.ownerships.count
          end
          should "record the deletion" do
            assert_not_nil Deletion.where(user: @user,
                                          rubygem: @rubygem.name,
                                          number: @v2.number).first
          end
        end
      end

      context "and a version 0.1.1 and platform x86-darwin-10" do
        setup do
          @v2 = create(:version, rubygem: @rubygem, number: "0.1.1", platform: "x86-darwin-10")
        end

        context "ON DELETE to create for version 0.1.1 and x86-darwin-10" do
          setup do
            delete :create, gem_name: @rubygem.to_param, version: @v2.number, platform: @v2.platform
          end
          should respond_with :success
          should "keep the gem, deindex it, and keep the owners" do
            assert_equal 2, @rubygem.versions.count
            assert_equal 1, @rubygem.versions.indexed.count
            assert_equal 1, @rubygem.ownerships.count
          end
          should "show platform in response" do
            assert_equal "Successfully deleted gem: SomeGem (0.1.1-x86-darwin-10)", @response.body
          end
          should "record the deletion" do
            assert_not_nil Deletion.where(
              user: @user,
              rubygem: @rubygem.name,
              number: @v2.number,
              platform: @v2.platform
            ).first
          end
        end
      end

      context "ON DELETE to create for existing gem with invalid version" do
        setup do
          delete :create, gem_name: @rubygem.to_param, version: "0.2.0"
        end
        should respond_with :not_found
        should "not modify any versions" do
          assert_equal 1, @rubygem.versions.count
          assert_equal 1, @rubygem.versions.indexed.count
        end
        should "not record the deletion" do
          assert_equal 0, @user.deletions.count
        end
      end

      context "ON DELETE to create for someone else's gem" do
        setup do
          @other_user = create(:user)
          @request.env["HTTP_AUTHORIZATION"] = @other_user.api_key
          delete :create, gem_name: @rubygem.to_param, version: '0.1.0'
        end
        should respond_with :forbidden
        should "not record the deletion" do
          assert_equal 0, @user.deletions.count
        end
      end

      context "ON DELETE to create for an already deleted gem" do
        setup do
          Deletion.create!(user: @user, version: @v1)
          delete :create, gem_name: @rubygem.to_param, version: @v1.number
        end
        should respond_with :unprocessable_entity
        should "not re-record the deletion" do
          assert_equal 1, Deletion.count(user: @user,
                                         rubygem: @rubygem.name,
                                         number: @v1.number)
        end
      end
    end

    context "for a gem SomeGem with a deleted version 0.1.0 and indexed version 0.1.1" do
      setup do
        @rubygem = create(:rubygem, name: "SomeGem")
        @v1 = create(:version,
          rubygem: @rubygem,
          number: "0.1.0",
          platform: "ruby",
          indexed: false)
        @v2 = create(:version,
          rubygem: @rubygem,
          number: "0.1.1",
          platform: "ruby")
        @v3 = create(:version,
          rubygem: @rubygem,
          number: "0.1.2",
          platform: "x86-darwin-10",
          indexed: false)
        create(:ownership, user: @user, rubygem: @rubygem)
      end

      context "ON PUT to destroy for version 0.1.0" do
        setup do
          put :destroy, gem_name: @rubygem.to_param, version: @v1.number
        end
        should respond_with :gone
      end

      context "ON PUT to destroy for version 0.1.2 and platform x86-darwin-10" do
        setup do
          put :destroy, gem_name: @rubygem.to_param, version: @v3.number, platform: @v3.platform
        end
        should respond_with :gone
      end

      context "ON PUT to destroy for version 0.1.1" do
        setup do
          put :destroy, gem_name: @rubygem.to_param, version: @v2.number
        end
        should respond_with :gone
      end
    end
  end
end
