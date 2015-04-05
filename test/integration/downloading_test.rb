require 'test_helper'

class DownloadingTest < ActionDispatch::IntegrationTest
  test "downloading a gem" do
    rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
    create(:version, rubygem: rubygem, number: "1.0.0", platform: "java")
    touch "/gems/sandworm-1.0.0.gem"
    touch "/gems/sandworm-1.0.0-java.gem"

    get rubygem_path("sandworm")
    assert page.has_content? "Total downloads 0"

    1.times do
      get "/gems/sandworm-1.0.0.gem"
    end

    2.times do
      get "/gems/sandworm-1.0.0-java.gem"
    end

    get rubygem_path("sandworm")
    assert page.has_content? "Total downloads 3"

    get rubygem_version_path("sandworm", "1.0.0")
    assert page.has_content? "For this version 1"

    get rubygem_version_path("sandworm", "1.0.0-java")
    assert page.has_content? "For this version 2"
  end

  private

  def touch(path)
    path = Pusher.server_path(path)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.touch(path)
  end
end
