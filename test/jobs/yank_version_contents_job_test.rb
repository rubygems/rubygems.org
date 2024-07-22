require "test_helper"
require "magic"

class YankVersionContentsJobTest < ActiveJob::TestCase
  setup do
    RubygemFs.mock!

    @user = create(:user)
    @api_key = create(:api_key, owner: @user)
    gem_file("bin_and_img-0.1.0.gem") { |gem| Pusher.new(@api_key, gem).process }
    @version = Version.last
    StoreVersionContentsJob.perform_now(version: @version)
    @rubygem = @version.rubygem
    @paths = @version.manifest.paths
    @checksums = @version.manifest.checksums

    assert_predicate @paths, :any?
    assert_predicate @checksums, :any?

    @version.update(indexed: false, yanked_at: Time.now.utc)
  end

  teardown do
    RubygemFs.mock!
  end

  def perform(version: @version)
    YankVersionContentsJob.perform_now(version:)
  end

  def perform_retries(version: @version)
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true
    perform(version:)
  ensure
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = false
  end

  context "a not found version" do
    should "raise on nil" do
      assert_raises(YankVersionContentsJob::VersionNotYanked) do
        perform_retries(version: nil)
      end
    end
  end

  context "a unyanked gem" do
    setup do
      @version.update(indexed: true, yanked_at: nil)
    end

    should "exit processing before doing anything" do
      assert_raises(YankVersionContentsJob::VersionNotYanked) do
        perform_retries
      end

      assert_equal @paths, @version.manifest.paths, "indexed paths should be unchanged"
      assert_equal @checksums, @version.manifest.checksums, "checksums should be unchanged"
    end
  end

  context "a yanked gem" do
    should "remove paths for the version" do
      perform

      assert_predicate @version.manifest.paths, :empty?, "indexed files should now be empty"
    end

    context "with no stored contents (as if already yanked or never uploaded)" do
      setup do
        perform
      end

      should "no-op gracefully" do
        assert_nil @version.manifest.spec
        assert_empty @version.manifest.paths
        assert_empty @version.manifest.checksums
        assert_empty @version.manifest.contents.keys

        perform
      end
    end

    context "only version" do
      should "remove spec" do
        perform

        assert_nil @version.manifest.spec
      end

      should "remove all paths" do
        perform

        assert_empty @version.manifest.paths
        @paths.each do |path|
          refute @version.manifest.entry(path), "file should not exist for #{path}"
        end
      end

      should "remove all checksums" do
        perform

        assert_empty @version.manifest.checksums
      end

      should "remove all stored contents" do
        perform

        @checksums.each do |path, checksum|
          refute @version.rubygem.file_content(checksum), "contents should not exist for #{path}"
        end
      end
    end

    context "with other versions" do
      setup do
        @new_version = create(:version, rubygem: @rubygem, number: "0.1.1", indexed: true)
        @new_paths = ["README.md", "LICENSE.txt", ".gitignore"]
        new_entries = @new_paths.map { |path| @version.manifest.entry(path) }
        @new_version.manifest.store_entries(new_entries)
        @new_checksums = @new_version.manifest.checksums
      end

      should "not remove shared files" do
        perform

        assert_equal @new_paths.sort, @new_version.manifest.paths.sort

        @new_paths.each do |path|
          assert @new_version.manifest.entry(path)
        end

        @new_checksums.each do |path, checksum|
          assert @rubygem.file_content(checksum), "contents should continue to exist for #{path}"
        end
      end

      should "remove only unique files" do
        perform

        @paths.each do |path|
          next if @new_paths.include?(path)

          refute @version.manifest.entry(path), "file by path should not exist for #{path}"
        end

        @checksums.each do |path, checksum|
          next if @new_checksums[path]

          refute @rubygem.file_content(checksum), "contents should not exist for #{path}"
        end
      end
    end
  end
end
