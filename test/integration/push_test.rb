require 'test_helper'

class PushTest < ActionDispatch::IntegrationTest
  setup do
    Dir.chdir(Dir.mktmpdir)
    @user = create(:user)
    cookies[:remember_token] = @user.remember_token
  end

  test "pushing a gem" do
    build_gem "sandworm", "1.0.0"

    push_gem "sandworm-1.0.0.gem"
    assert_response :success

    get rubygem_path("sandworm")
    assert_response :success
    assert page.has_content?("sandworm")
    assert page.has_content?("1.0.0")
  end

  test "pushing a jruby gem" do
    gem_name = build_gem("jruby-gem", "0.1.0", "test java gem", "jruby")

    push_gem(gem_name)

    gem_full_name = gem_name.sub(".gem", "")

    assert RubygemFs.instance.get("gems/#{gem_full_name}.gem")
    assert RubygemFs.instance.get("quick/Marshal.4.8/#{gem_full_name}.gemspec.rz")

    assert Version.find_by(full_name: gem_full_name)
  end

  test "push a new version of a gem" do
    rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
    create(:ownership, rubygem: rubygem, user: @user)

    build_gem "sandworm", "2.0.0"

    push_gem "sandworm-2.0.0.gem"
    assert_response :success

    get rubygem_path("sandworm")
    assert_response :success
    assert page.has_content?("sandworm")
    assert page.has_content?("2.0.0")
  end

  test "pushing a gem with a known dependency" do
    rubygem = create(:rubygem, name: "crysknife", number: "1.0.0")

    build_gem "sandworm", "1.0.0" do |gemspec|
      gemspec.add_runtime_dependency(rubygem.name, '> 0')
    end

    push_gem "sandworm-1.0.0.gem"

    get rubygem_path("sandworm")
    assert_response :success
    assert page.has_content?("crysknife")
    assert page.has_content?("> 0")
  end

  test "pushing a gem with an unknown dependency" do
    build_gem "sandworm", "1.0.0" do |gemspec|
      gemspec.add_runtime_dependency("mauddib", '> 1')
    end

    push_gem "sandworm-1.0.0.gem"

    get rubygem_path("sandworm")
    assert_response :success
    assert page.has_content?("mauddib")
    assert page.has_content?("> 1")
  end

  test "push errors bubble out" do
    push_gem Rails.root.join("test", "gems", "bad-characters-1.0.0.gem")

    assert_response :unprocessable_entity
    assert_match(/cannot process this gem/, response.body)
  end

  def push_gem(path)
    post api_v1_rubygems_path,
      env: { 'RAW_POST_DATA' => File.read(path) },
      headers: { "CONTENT_TYPE" => "application/octet-stream",
                 "HTTP_AUTHORIZATION" => @user.api_key }
  end

  teardown do
    Dir.chdir(Rails.root)
  end
end
