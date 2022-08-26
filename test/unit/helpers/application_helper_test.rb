require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  context "page title" do
    should "return title with subtitle" do
      assert_equal "#{t :title} | #{t :subtitle}", page_title
    end
    should "return with explicit title" do
      @title = "Sample"
      assert_equal "Sample | #{t :title} | #{t :subtitle}", page_title
    end
  end

  should "return gemcutter atom feed link" do
    feed_link = '<link rel="alternate" type="application/atom+xml" ' \
                'href="https://feeds.feedburner.com/gemcutter-latest" ' \
                'title="RubyGems.org | Latest Gems">'
    atom_feed_link_result = atom_feed_link(t(:feed_latest), "https://feeds.feedburner.com/gemcutter-latest")
    assert_equal feed_link, atom_feed_link_result
  end

  should "sanitize descriptions" do
    text = '<script>alert("foo");</script>Rails authentication & authorization'
    rubygem = create(:rubygem, name: "SomeGem")
    create(:version, rubygem: rubygem, number: "3.0.0", platform: "ruby", description: text)

    assert_equal "alert(&quot;foo&quot;);Rails authentication &amp; authorization",
      short_info(rubygem.versions.most_recent)
    assert_predicate short_info(rubygem.versions.most_recent), :html_safe?
  end

  context "rubygem" do
    setup do
      @rubygem = create(:rubygem)
      @rubygem.stubs(:downloads).returns(1_000_000)
    end
    should "downloads count with delimeter" do
      assert_equal("1,000,000", download_count(@rubygem))
    end

    should "stats graph meter" do
      most_downloaded_count = 8_000_000
      assert_in_delta(stats_graph_meter(@rubygem, most_downloaded_count), 12.5)
    end
  end

  context "flash_message string with html" do
    setup do
      @message = "This is a <strong>test</strong>"
    end

    should "sanitize with :notice_html" do
      assert_instance_of ActiveSupport::SafeBuffer, flash_message(:notice_html, @message)
    end

    should "not sanitize with :notice" do
      assert_instance_of String, flash_message(:notice, @message)
    end
  end
end
