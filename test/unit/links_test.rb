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

    assert_equal "http://www.rubydoc.info/gems/#{rubygem.name}/#{version.number}", links.documentation_uri
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
end
