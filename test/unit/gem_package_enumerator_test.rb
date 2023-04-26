require "test_helper"

class GemPackageEnumeratorTest < ActiveSupport::TestCase
  setup do
    @gem = gem_file("bin_and_img-0.1.0.gem")
    @gem_package = Gem::Package.new(@gem)
    @enum = GemPackageEnumerator.new(@gem_package)
    @destination_dir = Rails.root.join("tmp", "gems", @gem_package.spec.full_name)
    @gem_package.extract_files(@destination_dir.to_s) unless @destination_dir.join(@gem_package.spec.full_name).exist?
  end

  context "#map" do
    should "enumerate all the same files as Gem::Package#contents" do
      contents = @enum.map(&:full_name).to_a

      assert_equal @gem_package.contents, contents
    end

    should "yield each file start to finish, in order" do
      order = []
      entries = @enum.map do |entry|
        order << entry.full_name
        RubygemContents::Entry.from_tar_entry(entry)
      end
      entries.each do |entry|
        order << entry.path
      end
      expected = @gem_package.contents.flat_map { |path| [path, path] }

      assert_equal expected, order, "should touch each file twice before moving to the next file"
    end
  end

  should "match file for file with the extracted gem" do
    files_from_disk = {}

    @destination_dir.glob("**/*", File::FNM_DOTMATCH).each do |pathname|
      next if pathname.directory?
      files_from_disk[pathname.relative_path_from(@destination_dir).to_s] = pathname
    end

    entries = @enum.map do |entry|
      RubygemContents::Entry.from_tar_entry(entry)
    end

    entries.each do |entry|
      pathname = files_from_disk.delete(entry.path)

      assert pathname, "should have a corresponding file on disk for #{entry.path}"

      if pathname.symlink?
        assert_predicate entry, :symlink?, "#{entry.path} should be a symlink"
        assert_equal pathname.readlink.to_s, entry.linkname, "#{entry.path} should have the same linkname as the file on disk"
      elsif Magic.file(pathname.to_s).start_with?("text/")
        assert_equal pathname.read, entry.body, "#{entry.path} should have the same contents as the file on disk"
      else
        assert_equal Digest::SHA256.hexdigest(pathname.read), entry.sha256, "non text file #{entry.path} should have same sha256"
      end
    end

    assert_empty files_from_disk, "should have processed all files from disk"
  end
end
