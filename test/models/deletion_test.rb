require "test_helper"

class DeletionTest < ActiveSupport::TestCase
  include SearchKickHelper
  include ActiveJob::TestHelper

  setup do
    @user = create(:user)
    @api_key = create(:api_key, owner: @user)
    @gem_file = gem_file("test-0.0.0.gem")
    Pusher.new(@api_key, @gem_file).process
    @gem_file.rewind
    @version = Version.last
    @spec_rz = RubygemFs.instance.get("quick/Marshal.4.8/#{@version.full_name}.gemspec.rz")
    import_and_refresh
  end

  teardown do
    @gem_file.close
  end

  should "be indexed" do
    @version.indexed = false

    assert_predicate Deletion.new(version: @version, user: @user), :invalid?,
      "Deletion should only work on indexed gems"
  end

  context "association" do
    subject { Deletion.new(version: @version, user: @user) }

    should belong_to(:user).without_validating_presence
  end

  context "with deleted gem" do
    setup do
      @gem_name = @version.rubygem.name
      GemCachePurger.stubs(:call)
    end

    context "when delete is called" do
      setup do
        delete_gem
      end

      should "unindexes" do
        refute_predicate @version, :indexed?
        refute_predicate @version.rubygem, :indexed?
      end

      should "be considered deleted" do
        assert_includes Version.yanked, @version
      end

      should "no longer be latest" do
        refute_predicate @version.reload, :latest?
      end

      should "keep the yanked time" do
        assert @version.reload.yanked_at
      end

      should "set the yanked info checksum" do
        refute_nil @version.reload.yanked_info_checksum
      end

      should "delete the .gem file" do
        assert_nil RubygemFs.instance.get("gems/#{@version.full_name}.gem"), "Rubygem still exists!"
      end

      should "delete the .gemspec.rz file" do
        assert_nil RubygemFs.instance.get("quick/Marshal.4.8/#{@version.full_name}.gemspec.rz"), "Gemspec.rz still exists!"
      end

      should "send gem yanked email" do
        perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

        email = ActionMailer::Base.deliveries.last

        assert_equal "Gem #{@version.to_title} yanked from RubyGems.org", email.subject
        assert_equal [@user.email], email.to
      end
    end

    should "call GemCachePurger" do
      GemCachePurger.expects(:call).with(@gem_name)

      delete_gem
    end
  end

  should "enqueue yank version contents job" do
    assert_enqueued_jobs 1, only: YankVersionContentsJob do
      delete_gem
    end
  end

  should "enque job for updating ES index, spec index and purging cdn" do
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      assert_enqueued_jobs 8, only: FastlyPurgeJob do
        assert_enqueued_jobs 1, only: Indexer do
          assert_enqueued_jobs 1, only: ReindexRubygemJob do
            delete_gem
          end
        end
      end
    end

    perform_enqueued_jobs

    response = Searchkick.client.get index: "rubygems-#{Rails.env}",
                                                    id: @version.rubygem_id

    assert response["_source"]["yanked"]
  end

  should "record version metadata" do
    deletion = Deletion.new(version: @version, user: @user)

    assert_nil deletion.rubygem
    deletion.valid?

    assert_equal deletion.rubygem, @version.rubygem.name
    assert_equal @version.id, deletion.version_id
  end

  context "with restored gem" do
    setup do
      @gem_name = @version.rubygem.name
      GemCachePurger.stubs(:call)
      RubygemFs.instance.stubs(:restore).with do |file|
        case file
        when "gems/#{@version.full_name}.gem"
          RubygemFs.instance.store(file, @gem_file.read)
        when "quick/Marshal.4.8/#{@version.full_name}.gemspec.rz"
          RubygemFs.instance.store(file, @spec_rz)
        end
      end.returns(true)
    end

    context "when gem is deleted and restored" do
      setup do
        @deletion = delete_gem
        @deletion.restore!
      end

      should "index rubygem and version" do
        assert_predicate @version.rubygem, :indexed?
        assert_predicate @version, :indexed?
      end

      should "reorder versions" do
        assert_predicate @version.reload, :latest?
      end

      should "remove the yanked time and yanked_info_checksum" do
        assert_nil @version.yanked_at
        assert_nil @version.yanked_info_checksum
      end

      should "purge fastly" do
        Fastly.expects(:purge).with({ path: "info/#{@version.rubygem.name}", soft: true })
        Fastly.expects(:purge).with({ path: "names", soft: true })
        Fastly.expects(:purge).with({ path: "versions", soft: true })
        Fastly.expects(:purge).with({ path: "gem/#{@version.rubygem.name}", soft: true })

        Fastly.expects(:purge).with({ path: "gems/#{@version.full_name}.gem", soft: false }).times(2)
        Fastly.expects(:purge).with({ path: "quick/Marshal.4.8/#{@version.full_name}.gemspec.rz", soft: false }).times(2)

        perform_enqueued_jobs(only: FastlyPurgeJob)
      end

      should "remove deletion record" do
        assert_predicate @deletion, :destroyed?
      end
    end

    should "call GemCachePurger" do
      GemCachePurger.expects(:call).with(@gem_name).times(2)

      @deletion = delete_gem
      @deletion.restore!
    end

    should "enqueue store version contents job" do
      @deletion = delete_gem
      assert_enqueued_jobs 1, only: StoreVersionContentsJob do
        @deletion.restore!
      end
    end

    should "enqueue indexing jobs" do
      @deletion = delete_gem
      assert_enqueued_jobs 1, only: Indexer do
        assert_enqueued_jobs 1, only: UploadVersionsFileJob do
          assert_enqueued_with job: UploadInfoFileJob, args: [{ rubygem_name: @gem_name }] do
            @deletion.restore!
          end
        end
      end
    end
  end

  private

  def delete_gem
    Deletion.create!(version: @version, user: @user)
  end
end
