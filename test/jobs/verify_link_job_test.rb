# frozen_string_literal: true

require "test_helper"

class VerifyLinkJobTest < ActiveJob::TestCase
  LINKBACK_HTML = <<~HTML
    <html>
      <head>
        <title>Site with valid linkbacks</title>
        <link rel="rubygem" href="https://rubygems.org/gems/mygem">
      </head>
      <body>
        <a rel="rubygem" href="https://rubygems.org/gems/mygem/">
      </body>
    </html>
  HTML

  NO_LINKBACK_HTML = <<~HTML
    <html>
      <head>
        <title>Site with invalid linkbacks</title>
        <link rel="notarubygem" href="https://notrubygems.org/gems/mygem">
      </head>
      <body>
        <a rel="rubygem" href="https://rubygems.org/gems/notmygem/">notmygem</a>
      </body>
    </html>
  HTML

  GITHUB_HTML = <<~HTML
    <html>
      <head>
        <title>mygem on Github: a gem among gems</title>
      </head>
      <body>
        <a role="link" rel="noopener noreferrer nofollow" href="https://rubygems.org/gems/mygem">my github gem on rubygems.org</a>
      </body>
    </html>
  HTML

  GITHUB_PROFILE_HTML = <<~HTML
    <html>
      <head>
        <title>mygem on Github: a gem among gems</title>
      </head>
      <body>
        <a rel="me" href="https://rubygems.org/gems/mygem">my github gem on rubygems.org</a>
      </body>
    </html>
  HTML

  setup do
    @links = {
      home: "https://example.com",
      wiki: "https://example.com/no-linkback/",
      mail: "https://github.com/rubygems",
      docs: "http://example.com",
      code: "https://github.com/rubygems/mygem",
      bugs: "https://bad-url.com"
    }

    @rubygem = create(:rubygem, name: "mygem", linkset: build(:linkset, home: nil))
    @links.each do |link, url|
      LinkVerification.insert!({ linkable_id: @rubygem.id, linkable_type: "Rubygem", uri: url })
      instance_variable_set "@#{link}", LinkVerification.find_by!(linkable: @rubygem, uri: url)
    end

    assert_no_enqueued_jobs only: VerifyLinkJob

    stub_request(:get, @links[:home])
      .with(
        headers: {
          "Accept" => "text/html",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "User-Agent" => "RubyGems.org Linkback Verification/#{AppRevision.version}"
        }
      )
      .to_return(status: 200, body: LINKBACK_HTML, headers: {})

    stub_request(:get, @links[:docs])
      .with(
        headers: {
          "Accept" => "text/html",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "User-Agent" => "RubyGems.org Linkback Verification/#{AppRevision.version}"
        }
      )
      .to_return(status: 200, body: LINKBACK_HTML, headers: {})

    stub_request(:get, @links[:code])
      .with(
        headers: {
          "Accept" => "text/html",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "User-Agent" => "RubyGems.org Linkback Verification/#{AppRevision.version}"
        }
      )
      .to_return(status: 200, body: GITHUB_HTML, headers: {})

    stub_request(:get, @links[:mail])
      .with(
        headers: {
          "Accept" => "text/html",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "User-Agent" => "RubyGems.org Linkback Verification/#{AppRevision.version}"
        }
      )
      .to_return(status: 200, body: GITHUB_PROFILE_HTML, headers: {})

    stub_request(:get, @links[:wiki])
      .with(
        headers: {
          "Accept" => "text/html",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "User-Agent" => "RubyGems.org Linkback Verification/#{AppRevision.version}"
        }
      )
      .to_return(status: 200, body: NO_LINKBACK_HTML, headers: {})

    stub_request(:get, @links[:bugs])
      .to_return(status: 404, body: "", headers: {})
  end

  test "verifies link" do
    freeze_time

    VerifyLinkJob.perform_now(link_verification: @home)

    assert_predicate @home.reload, :verified?
    assert_equal Time.current, @home.last_verified_at
    assert_equal 0, @home.failures_since_last_verification
    assert_no_enqueued_jobs only: VerifyLinkJob
  end

  test "verifies github repo link" do
    freeze_time

    VerifyLinkJob.perform_now(link_verification: @code)

    assert_predicate @code.reload, :verified?
    assert_equal Time.current, @code.last_verified_at
    assert_equal 0, @code.failures_since_last_verification
    assert_no_enqueued_jobs only: VerifyLinkJob
  end

  test "verifies github profile link" do
    freeze_time

    VerifyLinkJob.perform_now(link_verification: @mail)

    assert_predicate @mail.reload, :verified?
    assert_equal Time.current, @mail.last_verified_at
    assert_equal 0, @mail.failures_since_last_verification
    assert_no_enqueued_jobs only: VerifyLinkJob
  end

  test "does not verify link if not found" do
    freeze_time

    VerifyLinkJob.perform_now(link_verification: @bugs)

    refute_predicate @bugs.reload, :verified?
    assert_nil @bugs.last_verified_at
    assert_equal 1, @bugs.failures_since_last_verification
    assert_enqueued_jobs 1, only: VerifyLinkJob
  end

  test "does not verify link for the wrong gem" do
    @wiki.update_columns(linkable_id: create(:rubygem, name: "other-gem").id)
    freeze_time

    VerifyLinkJob.perform_now(link_verification: @wiki)

    refute_predicate @wiki.reload, :verified?
    assert_nil @wiki.last_verified_at
    assert_equal 1, @wiki.failures_since_last_verification
    assert_enqueued_jobs 1, only: VerifyLinkJob
  end

  test "does not retry link verification after max failures" do
    @bugs.update_columns(failures_since_last_verification: LinkVerification::MAX_FAILURES - 1)
    freeze_time

    VerifyLinkJob.perform_now(link_verification: @bugs)

    refute_predicate @bugs.reload, :verified?
    assert_nil @bugs.last_verified_at
    assert_equal LinkVerification::MAX_FAILURES, @bugs.failures_since_last_verification
    assert_enqueued_jobs 0, only: VerifyLinkJob
  end

  test "does not retry link verification for http link" do
    freeze_time

    VerifyLinkJob.perform_now(link_verification: @docs)

    refute_predicate @docs.reload, :verified?
    assert_nil @docs.last_verified_at
    assert_equal 1, @docs.failures_since_last_verification
    assert_enqueued_jobs 0, only: VerifyLinkJob
  end
end
