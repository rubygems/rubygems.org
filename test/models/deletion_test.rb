require "test_helper"

class DeletionTest < ActiveSupport::TestCase
  include SearchKickHelper
  include ActiveJob::TestHelper

  setup do
    @user = create(:user)
    Pusher.new(@user, gem_file).process
    @version = Version.last
    import_and_refresh
  end

  should "be indexed" do
    @version.indexed = false

    assert_predicate Deletion.new(version: @version, user: @user), :invalid?,
      "Deletion should only work on indexed gems"
  end

  context "association" do
    subject { Deletion.new(version: @version, user: @user) }

    should belong_to :user
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

      should "send gem yanked email" do
        Delayed::Worker.new.work_off

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

  should "enque job for updating ES index, spec index and purging cdn" do
    assert_difference "Delayed::Job.count", 1 do
      assert_enqueued_jobs 7, only: FastlyPurgeJob do
        assert_enqueued_jobs 1, only: Indexer do
          assert_enqueued_jobs 1, only: ReindexRubygemJob do
            delete_gem
          end
        end
      end
    end

    Delayed::Worker.new.work_off
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
  end

  context "with restored gem" do
    setup do
      @gem_name = @version.rubygem.name
      GemCachePurger.stubs(:call)
      RubygemFs.instance.stubs(:restore).returns true
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

        Delayed::Worker.new.work_off
        perform_enqueued_jobs
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
  end

  private

  def delete_gem
    Deletion.create!(version: @version, user: @user)
  end
end
