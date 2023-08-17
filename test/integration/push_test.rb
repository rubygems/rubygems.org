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

    refute_nil RubygemFs.instance.get("gems/sandworm-2.0.0.gem")
    refute_nil RubygemFs.instance.get("quick/Marshal.4.8/sandworm-2.0.0.gemspec.rz")
    assert_equal({ checksum_sha256: rubygem.versions.find_by!(full_name: "sandworm-2.0.0").sha256, key: "gems/sandworm-2.0.0.gem" },
                 RubygemFs.instance.head("gems/sandworm-2.0.0.gem"))

    spec = Gem::Package.new("sandworm-2.0.0.gem").spec
    spec.abbreviate
    spec.sanitize
    spec_checksum = Digest::SHA256.base64digest Gem.deflate Marshal.dump spec

    assert_equal({ checksum_sha256: spec_checksum, key: "quick/Marshal.4.8/sandworm-2.0.0.gemspec.rz" },
                 RubygemFs.instance.head("quick/Marshal.4.8/sandworm-2.0.0.gemspec.rz"))

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

    assert_response :success

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

    assert_response :success

    get rubygem_path("sandworm")

    assert_response :success
    assert page.has_content?("mauddib")
    assert page.has_content?("> 1")
  end

  test "pushing a signed gem" do
    push_gem gem_file("valid_signature-0.0.0.gem")

    assert_response :success

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
    build_gem "sandworm", "1.0.0"

    assert_nil Rubygem.find_by(name: "sandworm")

    # Error on empty authors now happens in a different place,
    # but test what would happen if marshal dumping failed
    Gem::Specification.any_instance.stubs(:_dump).raises(NoMethodError)
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

    stub_request(:post, "https://api.hookrelay.dev/hooks/act/id/webhook_id-#{hook.id}").with(
      headers: {
        "Content-Type" => "application/json",
        "HR_TARGET_URL" => hook.url,
        "HR_MAX_ATTEMPTS" => "3"
      }
    ).and_return(status: 200, body: { id: :id123 }.to_json)
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
    perform_enqueued_jobs only: HookRelayReportJob

    assert_predicate hook.reload.failure_count, :zero?
    assert_equal 1, hook.successes_since_last_failure
    assert_equal 0, hook.failures_since_last_success
    assert_equal "2023-03-01T09:50:31+00:00".to_datetime, hook.last_success

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
        completed_at: "2023-03-01T09:51:31+00:00"
      },
      as: :json

    assert_response :success
    perform_enqueued_jobs only: HookRelayReportJob

    assert_equal 1, hook.reload.failure_count
    assert_equal 0, hook.successes_since_last_failure
    assert_equal 1, hook.failures_since_last_success
    assert_equal "2023-03-01T09:50:31+00:00".to_datetime, hook.last_success
    assert_equal "2023-03-01T09:51:31+00:00".to_datetime, hook.last_failure
  end

  context "with specially crafted gemspecs" do
    should "not allow overwriting gem with -\\d in name" do
      create(:version, number: "2.0", rubygem: create(:rubygem, name: "book-2"))

      build_gem_raw(file_name: "malicious.gem", spec: <<~YAML)
        --- !ruby/hash-with-ivars:Gem::Specification
        ivars:
          '@name': book
          '@version': '2-2.0'
          '@platform': 'not_ruby'
          '@original_platform': 'not-ruby'
          '@new_platform': ruby
          '@summary': 'malicious'
          '@authors': [test@example.com]
      YAML

      push_gem "malicious.gem"

      aggregate_assertions "should fail to push" do
        assert_response :conflict

        assert_nil Rubygem.find_by(name: "book")
        assert_nil RubygemFs.instance.get("gems/book-2-2.0.gem")
        assert_nil RubygemFs.instance.get("quick/Marshal.4.8/book-2-2.0.gemspec.rz")
      end
    end

    should "not allow overwriting platform gem" do
      create(:version, number: "2.0", platform: "universal-darwin-19", rubygem: create(:rubygem, name: "book"))

      build_gem_raw(file_name: "malicious.gem", spec: <<~YAML)
        --- !ruby/hash-with-ivars:Gem::Specification
        ivars:
          '@name': book-2.0-universal-darwin
          '@version': '19'
          '@platform': 'not_ruby'
          '@original_platform': 'not-ruby'
          '@new_platform': ruby
          '@summary': 'malicious'
          '@authors': [test@example.com]
      YAML

      push_gem "malicious.gem"

      aggregate_assertions "should fail to push" do
        assert_response :conflict

        assert_nil Rubygem.find_by(name: "book-2.0-universal-darwin")
        assert_nil RubygemFs.instance.get("gems/book-2.0-universal-darwin-19.gem")
        assert_nil RubygemFs.instance.get("quick/Marshal.4.8/book-2.0-universal-darwin-19.gemspec.rz")
      end
    end

    context "does not allow pushing a gem where the file name does not match the version full_name" do
      should "fail when original platform is a ruby Gem::Platform" do
        build_gem_raw(file_name: "malicious.gem", spec: <<~YAML)
          --- !ruby/object:Gem::Specification
          specification_version: 100
          name: book
          version: '1'
          platform: !ruby/object:Gem::Platform
            os: ruby
          summary: 'malicious'
          authors: [test@example.com]
        YAML
        push_gem "malicious.gem"

        aggregate_assertions "should fail to push" do
          assert_response :conflict

          assert_nil Rubygem.find_by(name: "book")
          assert_nil RubygemFs.instance.get("gems/book-1-ruby.gem")
          assert_nil RubygemFs.instance.get("quick/Marshal.4.8/book-1-ruby.gemspec.rz")
        end
      end

      should "fail when original platform is an array that resolves to a platform of ruby" do
        build_gem_raw(file_name: "malicious.gem", spec: <<~YAML)
          --- !ruby/object:Gem::Specification
          specification_version: 100
          name: book
          version: '1'
          platform: [ruby]
          summary: 'malicious'
          authors: [test@example.com]
        YAML
        push_gem "malicious.gem"

        assert_response :forbidden
      end
    end

    should "fail fast when spec.name is not a string" do
      build_gem_raw(file_name: "malicious.gem", spec: <<~YAML)
        --- !ruby/object:Gem::Specification
        name: !ruby/object:Gem::Version
          version: []
        version: '1'
        summary: 'malicious'
        authors: [test@example.com]
      YAML
      push_gem "malicious.gem"

      assert_response :unprocessable_entity
    end

    should "fail when spec.platform is invalid" do
      build_gem_raw(file_name: "malicious.gem", spec: <<~YAML)
        --- !ruby/hash-with-ivars:Gem::Specification
        ivars:
          '@name': book
          '@version': '1'
          '@new_platform': !ruby/object:Gem::Platform
            os: "../../../../../etc/passwd"
          '@original_platform': ruby
          '@summary': 'malicious'
          '@authors': [test@example.com]
      YAML
      push_gem "malicious.gem"

      assert_response :conflict
    end
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

  make_my_diffs_pretty!
end
