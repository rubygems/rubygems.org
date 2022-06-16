require "test_helper"

class PushTest < ActionDispatch::IntegrationTest
  setup do
    Dir.chdir(Dir.mktmpdir)
    @key = "12345"
    @user = create(:user)
    create(:api_key, user: @user, key: @key, push_rubygem: true)
  end

  test "pushing a gem" do
    build_gem "sandworm", "1.0.0"

    push_gem "sandworm-1.0.0.gem"
    assert_response :success

    get rubygem_path("sandworm")
    assert_response :success
    assert page.has_content?("sandworm")
    assert page.has_content?("1.0.0")
    assert page.has_content?("Pushed by")

    css = %(div.gem__users a[alt=#{@user.handle}])
    assert page.has_css?(css, count: 2)
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
      gemspec.add_runtime_dependency(rubygem.name, "> 0")
    end

    push_gem "sandworm-1.0.0.gem"

    get rubygem_path("sandworm")
    assert_response :success
    assert page.has_content?("crysknife")
    assert page.has_content?("> 0")
  end

  test "pushing a gem with an unknown dependency" do
    build_gem "sandworm", "1.0.0" do |gemspec|
      gemspec.add_runtime_dependency("mauddib", "> 1")
    end

    push_gem "sandworm-1.0.0.gem"

    get rubygem_path("sandworm")
    assert_response :success
    assert page.has_content?("mauddib")
    assert page.has_content?("> 1")
  end

  test "pushing a signed gem" do
    push_gem gem_file("valid_signature-0.0.0.gem")

    get rubygem_path("valid_signature")
    assert_response :success

    assert page.has_content?("Signature validity period")
    assert page.has_content?("August 31, 2021")
    assert page.has_content?("August 07, 2121")
    refute page.has_content?("(expired)")

    travel_to Time.zone.local(2121, 8, 8)
    get rubygem_path("valid_signature")
    assert page.has_content?("(expired)")
  end

  test "push errors bubble out" do
    push_gem Rails.root.join("test", "gems", "bad-characters-1.0.0.gem")

    assert_response :unprocessable_entity
    assert_match(/cannot process this gem/, response.body)
    assert_nil RubygemFs.instance.get("gems/bad-characters-1.0.0.gem")
    assert_nil RubygemFs.instance.get("quick/Marshal.4.8/bad-characters-1.0.0.gemspec.rz")
  end

  test "push errors don't save files" do
    build_gem "sandworm", "1.0.0" do |spec|
      spec.instance_variable_set :@authors, "string"
    end
    assert_nil Rubygem.find_by(name: "sandworm")
    push_gem "sandworm-1.0.0.gem"

    assert_response :internal_server_error
    assert_match(/problem saving your gem. Please try again./, response.body)

    rubygem = Rubygem.find_by(name: "sandworm")
    # assert_nil rubygem
    assert_empty rubygem.versions
    assert_nil Version.find_by(full_name: "sandworm-1.0.0")
    assert_nil RubygemFs.instance.get("gems/sandworm-1.0.0.gem")
    assert_nil RubygemFs.instance.get("quick/Marshal.4.8/sandworm-1.0.0.gemspec.rz")
  end

  test "republish a yanked version" do
    rubygem = create(:rubygem, name: "sandworm", owners: [@user])
    create(:version, number: "1.0.0", indexed: false, rubygem: rubygem)

    build_gem "sandworm", "1.0.0"

    push_gem "sandworm-1.0.0.gem"
    assert_response :conflict
    assert_match(/A yanked version already exists \(sandworm-1.0.0\)/, response.body)
  end

  test "republish a yanked version by a different owner" do
    rubygem = create(:rubygem, name: "sandworm")
    create(:version, number: "1.0.0", indexed: false, rubygem: rubygem)

    build_gem "sandworm", "1.0.0"

    push_gem "sandworm-1.0.0.gem"
    assert_response :conflict
    assert_match(/A yanked version pushed by a previous owner of this gem already exists \(sandworm-1.0.0\)/, response.body)
  end

  test "publishing a gem with ceritifcate but not signatures" do
    build_gem "sandworm", "2.0.0" do |gemspec|
      gemspec.cert_chain = [File.read(File.expand_path("../certs/chain.pem", __dir__))]
    end

    push_gem "sandworm-2.0.0.gem"
    assert_response :forbidden
    assert_match(/You have added cert_chain in gemspec but signature was empty/, response.body)
  end

  def push_gem(path)
    post api_v1_rubygems_path,
      env: { "RAW_POST_DATA" => File.read(path) },
      headers: { "CONTENT_TYPE" => "application/octet-stream",
                 "HTTP_AUTHORIZATION" => @key }
  end

  teardown do
    RubygemFs.mock!
    Dir.chdir(Rails.root)
  end
end
