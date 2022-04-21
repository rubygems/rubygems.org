require "test_helper"

class LinksTest < ActiveSupport::TestCase
  # #documentation_uri
  should "use linkset documentation_uri" do
    version = build(:version)
    rubygem = build(:rubygem, linkset: build(:linkset, docs: "http://example.com/doc"), versions: [version])
    links = rubygem.links(version)

    assert_match "http://example.com/doc", links.documentation_uri
  end

  should "fallback to rubygems documentation_uri" do
    version = build(:version)
    rubygem = build(:rubygem, linkset: build(:linkset, docs: nil), versions: [version])
    links = rubygem.links(version)

    assert_equal "https://www.rubydoc.info/gems/#{rubygem.name}/#{version.number}", links.documentation_uri
  end

  should "use all fields when indexed" do
    version = build(:version, indexed: true)
    rubygem = build(:rubygem, linkset: build(:linkset, docs: nil), versions: [version])
    links = rubygem.links(version)

    assert links.links.key?("home")
    assert links.links.key?("docs")
  end

  should "use partial fields when not indexed" do
    version = build(:version, indexed: false)
    rubygem = build(:rubygem, linkset: build(:linkset, docs: nil), versions: [version])
    links = rubygem.links(version)

    refute links.links.key?("home")
    assert links.links.key?("docs")
  end

  should "not use linkset value when any metadata uri attribute is set" do
    version = build(:version, metadata: { "wiki_uri" => "https://example.wiki" })
    linkset = build(:linkset, docs: "https://herebe.docs", code: "https://source.code")
    rubygem = build(:rubygem, linkset: linkset, versions: [version])
    links = rubygem.links(version)

    refute links.documentation_uri
    refute links.source_code_uri
    assert links.wiki_uri
  end

  should "use linkset value when homepage_uri attribute is empty" do
    version = build(:version, metadata: { "wiki_uri" => "https://example.wiki" })
    linkset = build(:linkset, home: "https://code.home")
    rubygem = build(:rubygem, linkset: linkset, versions: [version])
    links   = rubygem.links(version)

    assert links.homepage_uri
  end

  context "metadata includes unknown uri key" do
    setup do
      metadata = {
        "homepage_uri"        => "https://example.com",
        "source_code_uri"     => "https://example.com",
        "wiki_uri"            => "https://example.com",
        "mailing_list_uri"    => "https://example.com",
        "bug_tracker_uri"     => "https://example.com",
        "funding_uri"         => "https://example.com",
        "documentation_uri"   => "https://example.com",
        "changelog_uri"       => "https://example.com",
        "unknown_uri"         => "https://example.com"
      }

      version = build(:version, metadata: metadata)
      rubygem = build(:rubygem, versions: [version])
      @links = rubygem.links(version)
    end

    should "create method for known keys" do
      known_keys = Links::LINKS.values.reject! { |k| k == "download_uri" }
      known_keys.each do |key|
        assert_equal "https://example.com", @links.send(key), "value doesn't match for method: #{key}"
      end
    end

    should "not create method for unknown key" do
      refute_respond_to @links, "unknown_uri"
    end
  end
end
