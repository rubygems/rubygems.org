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
      wiki: "https://example.com/no-linkback/",
      mail: nil,
      docs: nil,
      code: "https://github.com/rubygems/mygem",
      bugs: "http://bad-url.com"
    }

    @rubygem = create(:rubygem, name: "mygem")
    @linkset = create(:linkset, **@links, rubygem: @rubygem)

    URI.stubs(:open).with("http://example.com").returns(stub(read: LINKBACK_HTML))
    URI.stubs(:open).with(@links[:code]).returns(stub(read: GITHUB_HTML))
    URI.stubs(:open).with(@links[:wiki]).returns(stub(read: NO_LINKBACK_HTML))
    URI.stubs(:open).with(@links[:bugs]).raises(Net::HTTPBadResponse)
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

  #   should "only run in the correct context" do
  #     assert @linkset.valid?
  #     refute @linkset.valid?(:verify_linkbacks)
  #   end
  #
  #   context "Verifying links for an indexed gem" do
  #     setup do
  #       version = build(:version, indexed: true)
  #       rubygem = build(
  #         :rubygem,
  #         versions: [version],
  #       )
  #       rubygem[:name] = "mygem"
  #
  #       @linkset = build(
  #         :linkset,
  #         **@links,
  #         rubygem: rubygem,
  #       )
  #
  #       @linkset.validate(:verify_linkbacks)
  #     end
  #
  #     should "record the results" do
  #       @linkset = build(:linkset)
  #       @linkset.validate(:verify_linkbacks)
  #
  #       Linkset::LINKS.map { |key|
  #         assert_not_nil @linkset["#{key}_verified"], "value doesn't match for method: #{key}"
  #       }
  #     end
  #
  #     context "using verify_linkbacks" do
  #       should "should save a record even if links fail URLs" do
  #         @linkset = create(:linkset)
  #         @linkset.rubygem[:indexed] = true
  #
  #         assert_changed(@linkset, :home_verified) do
  #           @linkset.verify_linkbacks
  #         end
  #       end
  #
  #       should "skip a non-indexed gem" do
  #       end
  #     end
  #
  #     should "not verify a rubygem.org gem link with a different gem name" do
  #       @linkset.rubygem.send("name=", "myOtherGem")
  #       @linkset.validate(:verify_linkbacks)
  #       refute @linkset[:home_verified]
  #       refute @linkset[:code_verified]
  #     end
  #
  #     should "find linkbacks on websites and Github" do
  #       assert @linkset[:home_verified]
  #       assert @linkset[:code_verified]
  #     end
  #
  #     should "not verify a site without a linkback" do
  #       refute @linkset[:wiki_verified]
  #     end
  #
  #     should "fail a bad URL" do
  #       refute @linkset[:bugs_verified]
  #     end
  #   end
end
