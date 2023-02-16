require "test_helper"

class LinkbackValidatorTest < ActiveSupport::TestCase
  LINKBACK_HTML = '
    <head>
        <title>Site with valid linkbacks</title>
        <link rel="rubygem" href="https://rubygems.org/gem/mygem">
      </head>
      <body>
        <a rel="rubygem" href="https://rubygems.org/gem/mygem/">
      </body>
    </html>'

  NO_LINKBACK_HTML = '
    <html>
        <head>
          <title>Site with invalid linkbacks</title>
          <link rel="notarubygem" href="https://notrubygems.org/gem/mygem">
        </head>
        <body>
          <a rel="rubygem" href="https://rubygems.org/gem/notmygem/">notmygem</a>
        </body>
      </html>
      '

  GITHUB_HTML = '
    <html>
      <head>
      <title>mygem on Github: a gem among gems</title>
      </head>
        <body>
          <a role="link" rel="noopener noreferrer nofollow" href="https://rubygems.org/gem/mygem">my github gem on rubygems.org</a>
        </body>
      </html>
    '

  links = {
    wiki: "https://example.com/no-linkback/",
    mail: nil,
    docs: nil,
    code: "https://github.com/rubygems/mygem",
    bugs: "http://bad-url.com",
  }

  setup do
    @linkset = build(:linkset, links)

    valid_linkback = mock
    valid_linkback.stubs(:read).returns LINKBACK_HTML

    github_scrape = mock
    github_scrape.stubs(:read).returns GITHUB_HTML

    no_linkback_scrape = mock
    no_linkback_scrape.stubs(:read).returns NO_LINKBACK_HTML

    URI.stubs(:open).with("http://example.com").returns(valid_linkback)
    URI.stubs(:open).with(links[:code]).returns(github_scrape)
    URI.stubs(:open).with(links[:wiki]).returns(no_linkback_scrape)
    URI.stubs(:open).with(links[:bugs]).raises(Net::HTTPBadResponse)
  end

  should "skip a non-indexed gem" do
    assert_no_changes "@linkset" do
      @linkset.validate(:verify_linkbacks)
    end
  end

  should "only run in the correct context" do
    assert @linkset.valid?
    refute @linkset.valid?(:verify_linkbacks)
  end

  context "Verifying links for an indexed gem" do
    setup do
      version = build(:version, indexed: true)
      rubygem = build(
        :rubygem,
        versions: [version],
      )
      rubygem[:name] = "mygem"

      @linkset = build(
        :linkset,
        **links,
        rubygem: rubygem,
      )

      @linkset.validate(:verify_linkbacks)
    end

    should "record the results" do
      @linkset = build(:linkset)
      @linkset.validate(:verify_linkbacks)

      Linkset::LINKS.map { |key|
        assert_not_nil @linkset["#{key}_verified"], "value doesn't match for method: #{key}"
      }
    end

    should "not verify a rubygem.org gem link with a different gem name" do
      @linkset.rubygem.send("name=", "myOtherGem")
      @linkset.validate(:verify_linkbacks)
      refute @linkset[:home_verified]
      refute @linkset[:code_verified]
    end

    should "find linkbacks on websites and Github" do
      assert @linkset[:home_verified]
      assert @linkset[:code_verified]
    end

    should "not verify a site without a linkback" do
      refute @linkset[:wiki_verified]
    end

    should "fail a bad URL" do
      refute @linkset[:bugs_verified]
    end
  end
end
