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
      bugs: "http://bad-url.com",
    }

    @rubygem = create(:rubygem, name: "mygem")
    @linkset = @rubygem.linkset
    @linkset.update!(@links)

    RestClient.stubs(:get).with { |url, **| url == @links[:home] }.returns(stub(body: LINKBACK_HTML))
    RestClient.stubs(:get).with { |url, **| url == @links[:code] }.returns(stub(body: GITHUB_HTML))
    RestClient.stubs(:get).with { |url, **| url == @links[:wiki] }.returns(stub(body: NO_LINKBACK_HTML))
    RestClient.stubs(:get).with { |url, **| url == @links[:bugs] }.raises(Net::HTTPBadResponse)
  end

  def perform(rubygem_id = @rubygem.id)
    VerifyLinkbacksJob.perform_now(rubygem_id)
  end

  def perform_retries(rubygem_id = @rubygem.id)
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true
    perform(rubygem_id)
  ensure
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = false
  end

  context "not indexed" do
    setup do
      @linkset = create(:linkset, @links)
    end

    should "not run" do
      assert_no_changes "@linkset" do
        assert_raise(ActiveRecord::RecordNotFound) do
          perform_retries(@rubygem.id)
        end
      end
    end
  end

  context "indexed gem" do
    setup do
      @rubygem.update!(indexed: true)
    end

    should "record which links are verified" do
      freeze_time do
        perform

        @linkset.reload

        assert_equal Date.current, @linkset.code_verified_at
        assert_equal Date.current, @linkset.home_verified_at
        assert_nil @linkset.docs_verified_at
        assert_nil @linkset.mail_verified_at
        assert_nil @linkset.bugs_verified_at
        assert_nil @linkset.wiki_verified_at
      end
    end

    should "not verify a rubygem.org gem link with the wrong gem name" do
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
