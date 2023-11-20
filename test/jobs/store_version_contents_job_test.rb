require "test_helper"

class StoreVersionContentsJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    RubygemFs.mock!

    @gem = gem_file("bin_and_img-0.1.0.gem")
    @user = create(:user)
    pusher = Pusher.new(create(:api_key, owner: @user), @gem)

    assert pusher.process, "gem should be pushed successfully: #{pusher.code} #{pusher.message}"
    @gem.rewind
    @gem_package = Gem::Package.new(@gem)
    @version = Version.last

    @destination_dir = Rails.root.join("tmp", "gems", @gem_package.spec.full_name)
    @gem_package.extract_files(@destination_dir.to_s) # TODO: expand once per test run?
  end

  def each_file_in_gem
    @destination_dir.glob("**/*", File::FNM_DOTMATCH).each do |pathname|
      next if pathname.directory?
      relative_path = pathname.relative_path_from(@destination_dir).to_s
      yield pathname, relative_path
    end
  end

  teardown do
    @gem&.close
    RubygemFs.mock!
  end

  def perform(version: @version)
    StoreVersionContentsJob.perform_now(version:)
  end

  def perform_retries(version: @version)
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true
    perform(version:)
  ensure
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = false
  end

  context "a not found version" do
    should "raise on nil" do
      assert_raises(StoreVersionContentsJob::VersionNotIndexed) do
        perform_retries(version: nil)
      end
    end
  end

  context "a not found gem" do
    should "raise on nil" do
      RubygemFs.instance.remove("gems/bin_and_img-0.1.0.gem")

      assert_raises(StoreVersionContentsJob::GemNotFound) do
        perform_retries
      end
    end
  end

  context "a corrupt gem" do
    should "raise Gem::Package::FormatError and discard job" do
      RubygemFs.instance.store("gems/bin_and_img-0.1.0.gem", "corrupt gem")

      assert_no_enqueued_jobs(only: StoreVersionContentsJob) do
        assert_raises(Gem::Package::FormatError) do
          perform
        end
      end
    end
  end

  context "a yanked gem" do
    setup do
      @version.update!(indexed: false, yanked_at: Time.now.utc)
    end

    should "exit processing before doing anything" do
      assert_predicate @version, :yanked?, "version should be yanked"

      assert_raises(StoreVersionContentsJob::VersionNotIndexed) do
        perform_retries
      end

      assert_nil @version.manifest.spec
      assert_predicate @version.manifest.paths, :empty?
      assert_predicate @version.manifest.checksums, :empty?
      assert_predicate @version.manifest.contents.keys, :empty?
    end
  end

  context "a valid gem" do
    should "store gem spec" do
      perform

      assert_equal @gem_package.spec.to_ruby, @version.manifest.spec
    end

    should "store checksums" do
      perform

      checksums = {}
      each_file_in_gem do |pathname, relative_path|
        checksums[relative_path] = Digest::SHA256.hexdigest(pathname.symlink? ? pathname.readlink.to_s : pathname.binread)
      end

      assert_predicate checksums, :any?, "gem source should have some checksums"
      assert_equal checksums, @version.manifest.checksums
    end

    should "store all the paths from the gem" do
      perform

      assert_equal @gem_package.contents.sort, @version.manifest.paths.sort
    end

    should "record symlinks" do
      perform

      each_file_in_gem do |pathname, relative_path|
        next unless pathname.symlink?
        entry = @version.manifest.entry(relative_path)

        assert_predicate entry, :symlink?, "symlink? should match for #{relative_path}"
        assert_equal pathname.readlink.to_s, entry.linkname, "linkname should match for symlink at #{relative_path}"
      end
    end

    should "record sha256 hexdigest of each file" do
      perform

      each_file_in_gem do |pathname, relative_path|
        entry = @version.manifest.entry(relative_path)
        if pathname.symlink?
          assert_equal Digest::SHA256.hexdigest(pathname.readlink.to_s), entry.sha256, "sha256 should match for #{relative_path}"
        else
          assert_equal Digest::SHA256.hexdigest(pathname.binread), entry.sha256, "sha256 should match for #{relative_path}"
        end
      end
    end

    should "record file mime types" do
      perform

      each_file_in_gem do |pathname, relative_path|
        next if pathname.symlink?
        entry = @version.manifest.entry(relative_path)

        assert_equal Magic.file(pathname.to_s, Magic::MIME), entry.mime, "mime should match for #{relative_path}"
      end
    end

    should "record file size" do
      perform

      each_file_in_gem do |pathname, relative_path|
        size = pathname.symlink? ? 0 : pathname.size
        entry = @version.manifest.entry(relative_path)

        assert_equal size, entry.size, "size should match for #{relative_path}"
      end
    end

    should "record file mode" do
      perform

      each_file_in_gem do |pathname, relative_path|
        next if pathname.symlink? # symlink mode is inconsistent across platforms
        entry = @version.manifest.entry(relative_path)
        fs_mode = (pathname.stat.mode & 0o777).to_fs(8) # only compare the last 3 octal digits

        assert_equal fs_mode, entry.file_mode.last(3), "mode should match for #{relative_path}"
      end
    end

    should "store all text file contents and attributes" do
      perform

      each_file_in_gem do |pathname, relative_path|
        next if pathname.symlink?
        body = pathname.binread
        next unless Magic.buffer(body, Magic::MIME).start_with?("text/")
        entry = @version.manifest.entry(relative_path)

        assert_equal body, entry.body, "contents should match for #{relative_path}"
      end
    end
  end
end
