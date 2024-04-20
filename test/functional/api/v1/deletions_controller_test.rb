require "test_helper"

class Api::V1::DeletionsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  context "with yank rubygem api key scope" do
    setup do
      @api_key = create(:api_key, key: "12345", yank_rubygem: true)
      @user = @api_key.user
      @request.env["HTTP_AUTHORIZATION"] = "12345"
    end

    context "with a gem version that is the suffix of another gem name" do
      setup do
        @owner     = create(:user)
        @rubygem   = create(:rubygem, name: "some-gem")
        @v1        = create(:version, rubygem: @rubygem, number: "0.1.0", platform: "ruby")
        @ownership = create(:ownership, user: @owner, rubygem: @rubygem)
        @user_gem  = create(:rubygem, name: "some")
        @user_v1   = create(:version, rubygem: @user_gem, number: "0.1.0", platform: "ruby")
        @user_own  = create(:ownership, user: @user, rubygem: @user_gem)
        RubygemFs.instance.store("gems/#{@v1.full_name}.gem", "")
      end

      context "ON DELETE" do
        setup do
          delete :create, params: { gem_name: "some", version: "gem-0.1.0" }
        end
        should respond_with :not_found
      end
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
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
        end

        context "ON DELETE to create for existing gem version without OTP" do
          setup do
            delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
          end
          should respond_with :unauthorized

          should "return body that starts with MFA enabled message" do
            assert @response.body.start_with?("You have enabled multifactor authentication")
          end
        end

        context "ON DELETE to create for existing gem version with incorrect OTP" do
          setup do
            @request.env["HTTP_OTP"] = (ROTP::TOTP.new(@user.totp_seed).now.to_i.succ % 1_000_000).to_s
            delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
          end
          should respond_with :unauthorized
        end

        context "ON DELETE to create for existing gem version with correct OTP" do
          setup do
            @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.totp_seed).now
            delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
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
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
        end

        context "api key has mfa enabled" do
          setup do
            @api_key.mfa = true
            @api_key.save!
            delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
          end
          should respond_with :unauthorized
        end

        context "api key does not have mfa enabled" do
          setup do
            delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
          end
          should respond_with :success
        end
      end

      context "when mfa is required in metadata" do
        setup do
          @v1.metadata = { "rubygems_mfa_required" => "true" }
          @v1.save!
        end

        context "when user has mfa enabled" do
          setup do
            @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
            @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.totp_seed).now
            delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
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
            delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
          end
          should respond_with :forbidden
        end
      end

      context "with api key gem scoped" do
        setup do
          @api_key = create(:api_key, name: "gem-scoped-delete-key", key: "123456", yank_rubygem: true, owner: @user, rubygem_id: @rubygem.id)
          @request.env["HTTP_AUTHORIZATION"] = "123456"
        end

        context "to the same gem to be deleted" do
          setup do
            delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
          end

          should respond_with :success
        end

        context "to another gem" do
          setup do
            ownership = create(:ownership, user: @user, rubygem: create(:rubygem, name: "another_gem"))
            @api_key.update(ownership: ownership)

            delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
          end

          should respond_with :forbidden
        end

        context "to a gem with ownership removed" do
          setup do
            ownership = create(:ownership, user: create(:user), rubygem: create(:rubygem, name: "test-gem123"))
            @api_key.update(ownership: ownership)
            ownership.destroy!

            delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
          end

          should respond_with :forbidden

          should "#render_soft_deleted_api_key and display an error" do
            assert_equal "An invalid API key cannot be used. Please delete it and create a new one.", @response.body
          end
        end
      end

      context "when mfa is required" do
        setup do
          User.any_instance.stubs(:mfa_required?).returns true
        end

        context "by user with mfa disabled" do
          setup do
            delete :create, params: { gem_name: @rubygem.name, version: @v1.number }
          end

          should respond_with :forbidden

          should "show error message" do
            mfa_error = <<~ERROR.chomp
              [ERROR] For protection of your account and your gems, you are required to set up multi-factor authentication \
              at https://rubygems.org/multifactor_auth/new.

              Please read our blog post for more details (https://blog.rubygems.org/2022/08/15/requiring-mfa-on-popular-gems.html).
            ERROR

            assert_includes @response.body, mfa_error
          end
        end

        context "by user on `ui_only` level" do
          setup do
            @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
            delete :create, params: { gem_name: @rubygem.name, version: @v1.number }
          end

          should respond_with :forbidden

          should "show error message" do
            mfa_error = <<~ERROR.chomp
              [ERROR] For protection of your account and your gems, you are required to change your MFA level to 'UI and gem signin' or 'UI and API' \
              at https://rubygems.org/settings/edit.

              Please read our blog post for more details (https://blog.rubygems.org/2022/08/15/requiring-mfa-on-popular-gems.html).
            ERROR

            assert_includes @response.body, mfa_error
          end
        end

        context "by user on `ui_and_gem_signin` level" do
          setup do
            @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)
            delete :create, params: { gem_name: @rubygem.name, version: @v1.number }
          end

          should respond_with :success

          should "not show error message" do
            refute_includes @response.body, "For protection of your account and your gems"
          end
        end

        context "by user on `ui_and_api` level" do
          setup do
            @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
            @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.totp_seed).now
            delete :create, params: { gem_name: @rubygem.name, version: @v1.number }
          end

          should respond_with :success

          should "not show error message" do
            refute_includes @response.body, "For protection of your account and your gems"
          end
        end
      end

      context "when mfa is required by metadata and user downloads" do
        setup do
          User.any_instance.stubs(:mfa_required?).returns true
          @v1.metadata = { "rubygems_mfa_required" => "true" }
          @v1.save!
        end

        context "by user with mfa disabled" do
          setup do
            delete :create, params: { gem_name: @rubygem.name, version: @v1.number }
          end

          should "only render one forbidden response" do
            assert_equal 403, @response.status
          end
        end
      end

      context "when mfa is recommended" do
        setup do
          User.any_instance.stubs(:mfa_recommended?).returns true

          another_gem = create(:rubygem, name: "gem_owned_by_someone_else")
          create(:version, rubygem: another_gem, number: "0.1.1", platform: "ruby")

          v2 = create(:version, rubygem: @rubygem, number: "0.1.1", platform: "ruby")
          Deletion.create!(user: @user, version: v2)

          @gems = {
            success: { name: @rubygem.slug, version: @v1.number, deletion_status: :success },
            already_deleted: { name: @rubygem.slug, version: v2.number, deletion_status: :unprocessable_entity },
            not_owned_gem: { name: another_gem.slug, version: @v1.number, deletion_status: :forbidden },
            without_version: { name: create(:rubygem).name, deletion_status: :not_found }
          }
        end

        context "by user with mfa disabled" do
          should "include mfa setup warning" do
            @gems.each_value do |gem|
              delete :create, params: { gem_name: gem[:name], version: gem[:version] }

              assert_response gem[:deletion_status]
              mfa_warning = <<~WARN.chomp


                [WARNING] For protection of your account and gems, we encourage you to set up multi-factor authentication \
                at https://rubygems.org/multifactor_auth/new. Your account will be required to have MFA enabled in the future.
              WARN

              assert_includes @response.body, mfa_warning
            end
          end
        end

        context "by user on `ui_only` mfa level" do
          setup do
            @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
          end

          should "include change mfa level warning" do
            @gems.each_value do |gem|
              delete :create, params: { gem_name: gem[:name], version: gem[:version] }

              assert_response gem[:deletion_status]
              mfa_warning = <<~WARN.chomp


                [WARNING] For protection of your account and gems, we encourage you to change your multi-factor authentication \
                level to 'UI and gem signin' or 'UI and API' at https://rubygems.org/settings/edit. \
                Your account will be required to have MFA enabled on one of these levels in the future.
              WARN

              assert_includes @response.body, mfa_warning
            end
          end
        end

        context "by user on `ui_and_gem_signin` mfa level" do
          setup do
            @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)
          end

          should "not include mfa warnings" do
            @gems.each_value do |gem|
              @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.totp_seed).now
              delete :create, params: { gem_name: gem[:name], version: gem[:version] }

              assert_response gem[:deletion_status]
              mfa_warning = "[WARNING] For protection of your account and gems"

              refute_includes @response.body, mfa_warning
            end
          end
        end

        context "by user on `ui_and_api` mfa level" do
          setup do
            @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          end

          should "not include mfa warnings" do
            @gems.each_value do |gem|
              @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.totp_seed).now
              delete :create, params: { gem_name: gem[:name], version: gem[:version] }

              assert_response gem[:deletion_status]
              mfa_warning = "[WARNING] For protection of your account and gems"

              refute_includes @response.body, mfa_warning
            end
          end
        end
      end

      context "with a soft deleted api key" do
        setup do
          @api_key.soft_delete!

          delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
        end

        should respond_with :forbidden

        should "#render_soft_deleted_api_key and display an error" do
          assert_equal "An invalid API key cannot be used. Please delete it and create a new one.", @response.body
        end
      end

      context "ON DELETE to create for existing gem version" do
        setup do
          create(:global_web_hook, user: @user, url: "http://example.org")
          delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
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
          assert_enqueued_jobs 1, only: NotifyWebHookJob
        end
        should "have enqueued reindexing job" do
          assert_enqueued_jobs 1, only: Indexer
          assert_enqueued_jobs 1, only: UploadVersionsFileJob
          assert_enqueued_jobs 1, only: UploadNamesFileJob
          assert_enqueued_with job: UploadInfoFileJob, args: [{ rubygem_name: @rubygem.name }]
        end
      end

      context "and a version 0.1.1" do
        setup do
          @v2 = create(:version, rubygem: @rubygem, number: "0.1.1", platform: "ruby")
        end

        context "ON DELETE to create for version 0.1.1" do
          setup do
            delete :create, params: { gem_name: @rubygem.slug, version: @v2.number }
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
            delete :create, params: { gem_name: @rubygem.slug, version: @v2.number, platform: @v2.platform }
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
          delete :create, params: { gem_name: @rubygem.slug, version: "0.2.0" }
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
          delete :create, params: { gem_name: other_rubygem.slug, version: "0.1.0" }
        end
        should respond_with :forbidden

        should "not record the deletion" do
          assert_equal 0, @user.deletions.count
        end
      end

      context "ON DELETE to create for an already deleted gem" do
        setup do
          Deletion.create!(user: @user, version: @v1)
          delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
        end
        should respond_with :unprocessable_entity

        should "not re-record the deletion" do
          assert_equal 1, Deletion.where(user: @user,
                                         rubygem: @rubygem.name,
                                         number: @v1.number).count
        end
      end
    end

    context "rubygem with no versions" do
      setup do
        @rubygem   = create(:rubygem, name: "no_versions")
        @ownership = create(:ownership, user: @user, rubygem: @rubygem)
      end

      context "ON DELETE to create for non existent version" do
        setup do
          delete :create, params: { gem_name: @rubygem.slug, version: "0.1.0" }
        end
        should respond_with :not_found

        should "not respond with not found message" do
          assert_equal "This rubygem could not be found.", @response.body
        end
        should "not record the deletion" do
          assert_empty Deletion.where(user: @user, rubygem: @rubygem.name, number: "0.1.0")
        end
      end
    end

    context "rubygem that is deletion ineligible" do
      context "with too many downloads" do
        setup do
          @rubygem   = create(:rubygem, name: "SomeGem")
          @v1        = create(:version, rubygem: @rubygem, number: "0.1.0", platform: "ruby")
          @ownership = create(:ownership, user: @user, rubygem: @rubygem)

          GemDownload.increment(
            100_001,
            rubygem_id: @rubygem.id,
            version_id: @v1.id
          )
          delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
        end

        should respond_with :forbidden

        should "respond with a message" do
          assert_equal(
            "Versions with more than 100,000 downloads cannot be deleted. " \
            "Please contact RubyGems support to request deletion of this version if it represents a legal or security risk.",
            @response.body
          )
        end
        should "not record the deletion" do
          assert_empty Deletion.where(user: @user, rubygem: @rubygem.name, number: @v1.number)
        end
        should "record a yank forbidden event" do
          assert_event Events::RubygemEvent::VERSION_YANK_FORBIDDEN, {
            number: @v1.number,
            platform: "ruby",
            yanked_by: @user.handle,
            version_gid: @v1.to_gid_param,
            actor_gid: @user.to_gid.to_s,
            reason: "Versions with more than 100,000 downloads cannot be deleted."
          }, @rubygem.events.where(tag: Events::RubygemEvent::VERSION_YANK_FORBIDDEN).sole
        end
      end

      context "published too long ago" do
        setup do
          travel_to 31.days.ago do
            @rubygem   = create(:rubygem, name: "SomeGem")
            @v1        = create(:version, rubygem: @rubygem, number: "0.1.0", platform: "ruby")
            @ownership = create(:ownership, user: @user, rubygem: @rubygem)
          end

          delete :create, params: { gem_name: @rubygem.slug, version: @v1.number }
        end

        should respond_with :forbidden

        should "respond with a message" do
          assert_equal(
            "Versions published more than 30 days ago cannot be deleted. " \
            "Please contact RubyGems support to request deletion of this version if it represents a legal or security risk.",
            @response.body
          )
        end
        should "not record the deletion" do
          assert_empty Deletion.where(user: @user, rubygem: @rubygem.name, number: @v1.number)
        end
        should "record a yank forbidden event" do
          assert_event Events::RubygemEvent::VERSION_YANK_FORBIDDEN, {
            number: @v1.number,
            platform: "ruby",
            yanked_by: @user.handle,
            version_gid: @v1.to_gid_param,
            actor_gid: @user.to_gid.to_s,
            reason: "Versions published more than 30 days ago cannot be deleted."
          }, @rubygem.events.where(tag: Events::RubygemEvent::VERSION_YANK_FORBIDDEN).sole
        end
      end
    end
  end

  context "without yank rubygem api key scope" do
    setup do
      api_key = create(:api_key, key: "12342")
      @request.env["HTTP_AUTHORIZATION"] = "12342"

      rubygem = create(:rubygem, number: "1.0.0", owners: [api_key.user])
      delete :create, params: { gem_name: rubygem.slug, version: "1.0.0" }
    end

    should respond_with :forbidden

    should "return body that starts with denied access message" do
      assert @response.body.start_with?("The API key doesn't have access")
    end
  end
end
