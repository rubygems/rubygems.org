require 'test_helper'

class PushTest < ActionDispatch::IntegrationTest
  setup do
    Dir.chdir(Rails.root.join("tmp"))
    @user = create(:user, email: "nick@example.com", api_key: "secret123")
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

  test "push a new version of a gem" do
    rubygem = create(:rubygem_with_version, name: "sandworm")
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
    rubygem = create(:rubygem_with_version, name: "crysknife")

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
    push_gem Rails.root.join("test/gems/bad-characters-1.0.0.gem")

    assert_response :unprocessable_entity
    assert_match /cannot process this gem/, response.body
  end

  def push_gem(path)
    post api_v1_rubygems_path, File.read(path), {"HTTP_AUTHORIZATION" => @user.api_key, "CONTENT_TYPE" => "application/octet-stream"}
  end

  teardown do
    Dir.chdir(Rails.root)
  end
end
