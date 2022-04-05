require "test_helper"

class Api::V1::DeletionsControllerTest < ActionController::TestCase
  context "with yank rubygem api key scope" do
    setup do
      @api_key = create(:api_key, key: "12345", yank_rubygem: true)
      @user = @api_key.user
      @request.env["HTTP_AUTHORIZATION"] = "12345"
    end

    context "for a gem SomeGem with a version 0.1.0" do
      setup do
        @rubygem   = create(:rubygem, name: "SomeGem")
        @v1        = create(:version, rubygem: @rubygem, number: "0.1.0", platform: "ruby")
        @ownership = create(:ownership, user: @user, rubygem: @rubygem)
        RubygemFs.instance.store("gems/#{@v1.full_name}.gem", "")
      end

      context "when mfa for UI and API is enabled" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
        end

        context "ON DELETE to create for existing gem version without OTP" do
          setup do
            delete :create, params: { gem_name: @rubygem.to_param, version: @v1.number }
          end
          should respond_with :unauthorized
        end

        context "ON DELETE to create for existing gem version with incorrect OTP" do
          setup do
            @request.env["HTTP_OTP"] = (ROTP::TOTP.new(@user.mfa_seed).now.to_i.succ % 1_000_000).to_s
            delete :create, params: { gem_name: @rubygem.to_param, version: @v1.number }
          end
          should respond_with :unauthorized
        end

        context "ON DELETE to create for existing gem version with correct OTP" do
          setup do
            @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
            delete :create, params: { gem_name: @rubygem.to_param, version: @v1.number }
          end
          should respond_with :success
          should "keep the gem, deindex, keep owner" do
            assert_equal 1, @rubygem.versions.count
            assert_predicate @rubygem.versions.indexed.count, :zero?
          end
          should "record the deletion" do
            assert_not_nil Deletion.where(user: @user,
                                          rubygem: @rubygem.name,
                                          number: @v1.number).first
          end
        end
      end

      context "when mfa for UI only is enabled" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
        end

        context "api key has mfa enabled" do
          setup do
            @api_key.mfa = true
            @api_key.save!
            delete :create, params: { gem_name: @rubygem.to_param, version: @v1.number }
          end
          should respond_with :unauthorized
        end

        context "api key does not have mfa enabled" do
          setup do
            delete :create, params: { gem_name: @rubygem.to_param, version: @v1.number }
          end
          should respond_with :success
        end
      end

      context "when mfa is required" do
        setup do
          @v1.metadata = { "rubygems_mfa_required" => "true" }
          @v1.save!
        end

        context "when user has mfa enabled" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
            @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
            delete :create, params: { gem_name: @rubygem.to_param, version: @v1.number }
          end
          should respond_with :success
          should "keep the gem, deindex, keep owner" do
            assert_equal 1, @rubygem.versions.count
            assert_predicate @rubygem.versions.indexed.count, :zero?
          end
          should "record the deletion" do
            assert_not_nil Deletion.where(user: @user,
                                          rubygem: @rubygem.name,
                                          number: @v1.number).first
          end
        end

        context "when user has not mfa enabled" do
          setup do
            delete :create, params: { gem_name: @rubygem.to_param, version: @v1.number }
          end
          should respond_with :forbidden
        end
      end

      context "with api key gem scoped" do
        setup do
          @api_key = create(:api_key, name: "gem-scoped-delete-key", key: "123456", yank_rubygem: true, user: @user, rubygem_id: @rubygem.id)
          @request.env["HTTP_AUTHORIZATION"] = "123456"
        end

        context "to the same gem to be deleted" do
          setup do
            delete :create, params: { gem_name: @rubygem.to_param, version: @v1.number }
          end

          should respond_with :success
        end

        context "to another gem" do
          setup do
            ownership = create(:ownership, user: @user, rubygem: create(:rubygem, name: "another_gem"))
            @api_key.update(ownership: ownership)

            delete :create, params: { gem_name: @rubygem.to_param, version: @v1.number }
          end

          should respond_with :forbidden
        end
      end

      context "ON DELETE to create for existing gem version" do
        setup do
          create(:global_web_hook, user: @user, url: "http://example.org")
          delete :create, params: { gem_name: @rubygem.to_param, version: @v1.number }
        end
        should respond_with :success
        should "keep the gem, deindex, keep owner" do
          assert_equal 1, @rubygem.versions.count
          assert_predicate @rubygem.versions.indexed.count, :zero?
        end
        should "record the deletion" do
          assert_not_nil Deletion.where(user: @user,
                                        rubygem: @rubygem.name,
                                        number: @v1.number).first
        end
        should "have enqueued a webhook" do
          assert_instance_of Notifier, Delayed::Job.last.payload_object
        end
      end

      context "and a version 0.1.1" do
        setup do
          @v2 = create(:version, rubygem: @rubygem, number: "0.1.1", platform: "ruby")
        end

        context "ON DELETE to create for version 0.1.1" do
          setup do
            delete :create, params: { gem_name: @rubygem.to_param, version: @v2.number }
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
            delete :create, params: { gem_name: @rubygem.to_param, version: @v2.number, platform: @v2.platform }
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
          delete :create, params: { gem_name: @rubygem.to_param, version: "0.2.0" }
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
          other_user = create(:user)
          other_rubygem = create(:rubygem, name: "SomeOtherGem")
          create(:version, rubygem: other_rubygem, number: "0.1.0", platform: "ruby")
          create(:ownership, user: other_user, rubygem: other_rubygem)
          delete :create, params: { gem_name: other_rubygem.to_param, version: "0.1.0" }
        end
        should respond_with :forbidden
        should "not record the deletion" do
          assert_equal 0, @user.deletions.count
        end
      end

      context "ON DELETE to create for an already deleted gem" do
        setup do
          Deletion.create!(user: @user, version: @v1)
          delete :create, params: { gem_name: @rubygem.to_param, version: @v1.number }
        end
        should respond_with :unprocessable_entity
        should "not re-record the deletion" do
          assert_equal 1, Deletion.where(user: @user,
                                         rubygem: @rubygem.name,
                                         number: @v1.number).count
        end
      end
    end
  end

  context "without yank rubygem api key scope" do
    setup do
      api_key = create(:api_key, key: "12342")
      @request.env["HTTP_AUTHORIZATION"] = "12342"

      rubygem = create(:rubygem, number: "1.0.0", owners: [api_key.user])
      delete :create, params: { gem_name: rubygem.to_param, version: "1.0.0" }
    end

    should respond_with :forbidden
  end
end
