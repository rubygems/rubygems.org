require "test_helper"

class VersionContentsTest < SystemTest
  include ActiveJob::TestHelper

  setup do
    @gem = gem_file("bin_and_img-0.1.0.gem")
    @user = create(:user)
    Pusher.new(@user, @gem).process
    @gem.close

    @latest_version = Version.last
    @rubygem = @latest_version.rubygem
    StoreVersionContentsJob.perform_now(version: @latest_version)

    @dirs = %w[exe/ img/ lib/]
    @files = %w[.gitignore .rspec Gemfile LICENSE.txt README.md bin_and_img.gemspec]
  end

  def contents_path(path)
    rubygem_version_contents_path(@rubygem.name, @latest_version.slug, path:)
  end

  context "routing to index" do
    should "route to root" do
      expected = { controller: "version_contents", action: "index", rubygem_id: "foo", version_id: "1.0.0", format: "html" }

      assert_routing "/gems/foo/versions/1.0.0/contents", expected
    end
  end

  context "routing to show" do
    should "route to dir" do
      expected = { controller: "version_contents", action: "show", rubygem_id: "foo", version_id: "1.0.0", path: "lib", format: "html" }

      assert_routing "/gems/foo/versions/1.0.0/contents/lib", expected
    end

    should "route to nested dir" do
      expected = { controller: "version_contents", action: "show", rubygem_id: "foo", version_id: "1.0.0", path: "lib/rake", format: "html" }

      assert_routing "/gems/foo/versions/1.0.0/contents/lib/rake", expected
    end

    should "route to file" do
      expected = { controller: "version_contents", action: "show", rubygem_id: "foo", version_id: "1.0.0", path: "foo.rb", format: "html" }

      assert_routing "/gems/foo/versions/1.0.0/contents/foo.rb", expected
    end

    should "route to nested file" do
      expected = { controller: "version_contents", action: "show", rubygem_id: "foo", version_id: "1.0.0", path: "lib/foo.rb", format: "html" }

      assert_routing "/gems/foo/versions/1.0.0/contents/lib/foo.rb", expected
    end

    should "not be confused by formats that could be interpretted as a format by rails routes" do
      %w[json yaml html gemspec sha256 js].each do |format|
        expected = { controller: "version_contents", action: "show", rubygem_id: "foo", version_id: "1.0.0", path: "foo.#{format}", format: "html" }

        assert_routing "/gems/foo/versions/1.0.0/contents/foo.#{format}", expected
      end
    end
  end

  context "GET contents" do
    should "render contents of the gem version" do
      visit "/gems/#{@rubygem.name}/versions/#{@latest_version.slug}/contents"

      assert page.has_content?(@rubygem.name), "Rubygem name is not present"
      assert page.has_content?(@latest_version.number), "Version number is not present"

      @dirs.each do |dir|
        assert page.has_link?(dir, href: contents_path(dir)), "Directory link #{dir.inspect} is not present"
      end

      @files.each do |file|
        assert page.has_link?(file, href: contents_path(dir)), "File link #{file.inspect} is not present"
      end
    end
  end

  context "GET file contents" do
    should "render contents of the gemspec" do
      visit "/gems/#{@rubygem.name}/versions/#{@latest_version.slug}/contents/#{@rubygem.name}.gemspec"

      assert page.has_content?(@rubygem.name), "Rubygem name is not present"
      assert page.has_content?(@latest_version.number), "Version number is not present"

      assert page.has_content?("Gem::Specification.new do |spec|"), "Gemspec content is not present"
    end
  end
end
