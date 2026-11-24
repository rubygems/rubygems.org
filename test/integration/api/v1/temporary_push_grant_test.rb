# frozen_string_literal: true

require "test_helper"

# Pushes through the real API endpoint with an operator-issued temporary push grant key.
class Api::V1::TemporaryPushGrantTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create(:user)
    @rubygem = create(:rubygem, name: "abandoned", owners: [@owner])
    create(:version, rubygem: @rubygem, number: "0.9.0")

    @grantee = create(:user)
    @grantee.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    @ruby_gem = gem_body("1.0.0")
    @linux_gem = gem_body("1.0.0", "x86_64-linux")

    @grant = create(:temporary_push_grant, rubygem: @rubygem, grantee: @grantee, version: "1.0.0")
    @ruby_artifact = create(:temporary_push_grant_artifact, temporary_push_grant: @grant, platform: "ruby", sha256: hex(@ruby_gem))
    create(:temporary_push_grant_artifact, temporary_push_grant: @grant, platform: "x86_64-linux", sha256: hex(@linux_gem))
    @key = approve_review_and_activate(@grant)
  end

  test "publishes each approved artifact once, attributed to the grantee, without changing ownership" do
    push @ruby_gem

    assert_response :success
    version = @rubygem.versions.find_by!(number: "1.0.0", platform: "ruby")

    assert_equal @grantee, version.pusher
    assert_equal @grant.api_key, version.pusher_api_key
    assert_equal version, @ruby_artifact.reload.version
    assert_equal [@owner], @rubygem.reload.owners_including_unconfirmed.to_a
    refute @grantee.owns_gem?(@rubygem)
    assert_equal :active, @grant.reload.status

    push @linux_gem

    assert_response :success
    assert_equal :completed, @grant.reload.status

    push @ruby_gem # identical retry

    assert_response :success
    assert_equal "Gem was already pushed: abandoned (1.0.0)", response.body.lines.first.chomp
    assert_equal 2, @rubygem.versions.where(number: "1.0.0").count
  end

  test "requires MFA on every upload, even though the grantee's MFA level does not cover the API" do
    push @ruby_gem, otp: nil

    assert_response :unauthorized
    push @ruby_gem, otp: "000000"

    assert_response :unauthorized
    assert_nil @ruby_artifact.reload.version
  end

  test "refuses different bytes bearing an approved name, and an unapproved version, platform, or gem" do
    push gem_body("1.0.0") { |s| s.summary = "tampered" }

    assert_response :forbidden
    assert_match "does not match the reviewed checksum for abandoned 1.0.0 (ruby)", response.body

    push gem_body("1.0.1")

    assert_response :forbidden
    assert_match "only authorizes version 1.0.0", response.body

    push gem_body("1.0.0", "java")

    assert_response :forbidden
    assert_match "does not authorize the java platform", response.body

    create(:rubygem, name: "other", owners: [create(:user)])
    push gem_body("1.0.0", name: "other")

    assert_response :forbidden
    push gem_body("1.0.0", name: "brand-new")

    assert_response :forbidden
    assert_nil Rubygem.find_by(name: "brand-new")
    assert_empty Version.where(number: %w[1.0.0 1.0.1])
  end

  test "refuses uploads after expiry, suspension, and revocation, without restarting the clock" do
    travel_to @grant.expires_at + 1.second do
      push @ruby_gem

      assert_response :unauthorized # the key itself expired with the grant
    end

    @grant.suspend!("Owner replied; clarifying their wishes")
    push @ruby_gem

    assert_response :forbidden
    assert_match "suspended", response.body

    expires_at = @grant.expires_at
    @grant.resume!

    assert_equal expires_at, @grant.reload.expires_at

    @grant.revoke!("Owner objected")
    push @ruby_gem

    assert_response :unauthorized
    assert_empty Version.where(number: "1.0.0")
  end

  test "a revocation committed after the upload authenticated still stops it" do
    pusher = Pusher.new(ApiKey.find(@grant.api_key_id), @ruby_gem) # authenticated before the revocation below
    @grant.revoke!("Evidence of compromise")

    refute pusher.process
    assert_equal 403, pusher.code
    assert_match "revoked", pusher.message
    assert_empty Version.where(number: "1.0.0")
  end

  test "an upload whose gem file was not stored does not consume the artifact's allowance" do
    RubygemFs.instance.stubs(:store).raises(StandardError, "storage unavailable")
    push @ruby_gem

    assert_response :internal_server_error
    assert_nil @ruby_artifact.reload.version

    RubygemFs.instance.unstub(:store)
    push @ruby_gem

    assert_response :success
    assert_predicate @ruby_artifact.reload, :published?
  end

  test "the grant key cannot yank, manage owners, or be widened by its holder" do
    version = @rubygem.versions.sole

    delete "/api/v1/gems/yank", params: { gem_name: @rubygem.name, version: version.number },
      headers: { HTTP_AUTHORIZATION: @key, HTTP_OTP: otp }

    assert_response :forbidden
    post "/api/v1/gems/#{@rubygem.name}/owners", params: { email: @grantee.email },
      headers: { HTTP_AUTHORIZATION: @key, HTTP_OTP: otp }

    assert_response :forbidden
    refute_predicate version.reload, :yanked?
    refute @grantee.owns_gem?(@rubygem)

    api_key = @grant.api_key

    refute api_key.update(scopes: %i[push_rubygem yank_rubygem])
    refute api_key.reload.update(mfa: false)
  end

  test "ordinary keys of the grantee gain no authority from the grant" do
    create(:api_key, owner: @grantee, key: "ordinary", scopes: %i[push_rubygem])

    post "/api/v1/gems", params: @ruby_gem.string,
      headers: { HTTP_AUTHORIZATION: "ordinary", CONTENT_TYPE: "application/octet-stream" }

    assert_response :forbidden
    assert_match "You do not have permission to push to this gem", response.body
  end

  test "owners keep pushing with their ordinary keys" do
    create(:api_key, owner: @owner, key: "owner-key", scopes: %i[push_rubygem])

    post "/api/v1/gems", params: gem_body("2.0.0").string,
      headers: { HTTP_AUTHORIZATION: "owner-key", CONTENT_TYPE: "application/octet-stream" }

    assert_response :success
    assert_equal @owner, @rubygem.versions.find_by!(number: "2.0.0").pusher
  end

  private

  def gem_body(number, platform = "ruby", name: "abandoned", &)
    build_gem(new_gemspec(name, number, "A gem", platform, &))
  end

  def hex(body)
    Digest::SHA256.hexdigest(body.string)
  end

  def otp
    ROTP::TOTP.new(@grantee.reload.totp_seed).now
  end

  def push(body, otp: self.otp)
    headers = { HTTP_AUTHORIZATION: @key, CONTENT_TYPE: "application/octet-stream" }
    headers[:HTTP_OTP] = otp if otp
    post "/api/v1/gems", params: body.string, headers:
  end

  def approve_review_and_activate(grant)
    grant.approve!(create(:admin_github_user, :is_admin, login: "operator-one"), conflict_disclosure: "None")
    grant.approve!(create(:admin_github_user, :is_admin, login: "operator-two"), conflict_disclosure: "None")
    grant.record_technical_review!(reviewer: "reviewer", notes: "Suite passes; diff and built gems reviewed.")
    grant.activate!
    ActionMailer::Base.deliveries.last.body.to_s[/rubygems_\h{48}/]
  end
end
