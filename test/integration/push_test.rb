require "test_helper"

class PushTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

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

  setup do
    @act = ENV["HOOK_RELAY_ACCOUNT_ID"]
    @id = ENV["HOOK_RELAY_HOOK_ID"]
    ENV["HOOK_RELAY_ACCOUNT_ID"] = "act"
    ENV["HOOK_RELAY_HOOK_ID"] = "id"
  end

  teardown do
    ENV["HOOK_RELAY_ACCOUNT_ID"] = @act
    ENV["HOOK_RELAY_HOOK_ID"] = @id
  end

  test "publishing a gem with webhook subscribers" do
    hook = create(:global_web_hook)

    build_gem "sandworm", "2.0.0"
    push_gem "sandworm-2.0.0.gem"

    assert_response :success

    RestClient::Request.expects(:execute).with(has_entries(
                                                 method: :post,
                                                 url: "https://api.hookrelay.dev/hooks/act/id/webhook_id-#{hook.id}",
                                                 headers: has_entries(
                                                   "Content-Type" => "application/json",
                                                   "HR_TARGET_URL" => hook.url,
                                                   "HR_MAX_ATTEMPTS" => "3"
                                                 )
                                               )).returns({ id: :id123 }.to_json)
    perform_enqueued_jobs only: NotifyWebHookJob

    assert_predicate hook.reload.failure_count, :zero?

    post hook_relay_report_api_v1_web_hooks_path,
      params: {
        attempts: 3,
        account_id: "act",
        hook_id: "id",
        id: "01GTE93BNWPD0VF0V4QCJ7NDSF",
        created_at: "2023-03-01T09:47:18Z",
        request: {
          body: "{}",
            headers: {
              Authorization: "51bf53d06ac382585b83e6f3241c950710ee53368e948ac309b7869c974338e9",
                "User-Agent": "rest-client/2.1.0 (darwin22 arm64) ruby/3.2.1p31",
                Accept: "*/*",
                "Content-Type": "application/json"
            },
            target_url: "https://example.com/rubygem0"
        },
        report_url: "https://rubygems.org/api/v1/web_hooks/hook_relay_report",
        max_attempts: 3,
        status: "success",
        last_attempted_at: "2023-03-01T09:50:31+00:00",
        stream: "hook:act:id:webhook_id-#{hook.id}",
        completed_at: "2023-03-01T09:50:31+00:00"
      },
      as: :json
    assert_response :success
    assert_predicate hook.reload.failure_count, :zero?

    post hook_relay_report_api_v1_web_hooks_path,
      params: {
        attempts: 3,
        account_id: "act",
        hook_id: "id",
        id: "01GTE93BNWPD0VF0V4QCJ7NDSF",
        created_at: "2023-03-01T09:47:18Z",
        request: {
          body: "{}",
            headers: {
              Authorization: "51bf53d06ac382585b83e6f3241c950710ee53368e948ac309b7869c974338e9",
                "User-Agent": "rest-client/2.1.0 (darwin22 arm64) ruby/3.2.1p31",
                Accept: "*/*",
                "Content-Type": "application/json"
            },
            target_url: "https://example.com/rubygem0"
        },
        report_url: "https://rubygems.org/api/v1/web_hooks/hook_relay_report",
        max_attempts: 3,
        status: "failure",
        last_attempted_at: "2023-03-01T09:50:31+00:00",
        stream: "hook:act:id:webhook_id-#{hook.id}",
        failure_reason: "Exhausted attempts",
        completed_at: "2023-03-01T09:50:31+00:00"
      },
      as: :json
    assert_response :success
    assert_equal 1, hook.reload.failure_count
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
