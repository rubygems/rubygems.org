# frozen_string_literal: true

require "test_helper"

class VerifyLinkbacksJobTest < ActiveJob::TestCase
  LINKBACK_HTML = <<~HTML
    <html>
      <head>
        <title>Site with valid linkbacks</title>
        <link rel="rubygem" href="https://rubygems.org/gem/mygem">
      </head>
      <body>
        <a rel="rubygem" href="https://rubygems.org/gem/mygem/">
      </body>
    </html>
  HTML

  NO_LINKBACK_HTML = <<~HTML
    <html>
      <head>
        <title>Site with invalid linkbacks</title>
        <link rel="notarubygem" href="https://notrubygems.org/gem/mygem">
      </head>
      <body>
        <a rel="rubygem" href="https://rubygems.org/gem/notmygem/">notmygem</a>
      </body>
    </html>
  HTML

  GITHUB_HTML = <<~HTML
    <html>
      <head>
        <title>mygem on Github: a gem among gems</title>
      </head>
      <body>
        <a role="link" rel="noopener noreferrer nofollow" href="https://rubygems.org/gem/mygem">my github gem on rubygems.org</a>
      </body>
    </html>
  HTML

  setup do
    @links = {
      home: "http://example.com",
      wiki: "https://example.com/no-linkback/",
      mail: nil,
      docs: nil,
      code: "https://github.com/rubygems/mygem",
      bugs: "http://bad-url.com"
    }

    @rubygem = create(:rubygem, name: "mygem")
    @linkset = @rubygem.linkset
    @linkset.update!(@links)

    stub_request(:get, @links[:home])
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

  def perform(linkset: @rubygem.linkset)
    VerifyLinkbacksJob.perform_now(linkset:)
  end

  def perform_retries(linkset: @rubygem.linkset)
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true
    perform(linkset:)
  ensure
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = false
  end

  context "Linkback verification for" do
    context "a non-indexed gem" do
      setup do
        @linkset = create(:linkset, @links)
      end

      should "not run" do
        assert_no_changes "@linkset" do
          perform_retries(linkset: @rubygem.linkset)
        end
      end
    end

    context "an indexed gem" do
      setup do
        @rubygem.update!(indexed: true)
      end

      should "record which links are verified" do
        verified_at_keys = Linkset::LINKS.map { |i| "#{i}_verified_at" }

        freeze_time do
          perform

          @linkset.reload

          assert_equal Date.current, @linkset.code_verified_at
          assert_equal Date.current, @linkset.home_verified_at

          verified_at_keys.without("code_verified_at", "home_verified_at").each do |link|
            assert_nil @linkset["#{link}_verified_at"]
          end
        end
      end

      should "enqueue a job to verify linkbacks" do
        assert_enqueued_with(job: VerifyLinkbacksJob, args: [{ linkset: @linkset }]) do
          @linkset.save!
        end
      end

      should "not verify a linkback with the wrong gem name" do
        @rubygem.update!(name: "myOtherGem")

        perform

        @linkset.reload

        refute @linkset.code_verified_at
        refute @linkset.home_verified_at
      end

      should "time out safely when a link doesn't respond" do
        URI.stubs(:open).with(@links[:bugs]).raises(Timeout::Error)

        perform

        @linkset.reload

        refute @linkset.bugs_verified_at
      end
    end
  end
end
