require 'test_helper'

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

    assert links.links.key?('home')
    assert links.links.key?('docs')
  end

  should "use partial fields when not indexed" do
    version = build(:version, indexed: false)
    rubygem = build(:rubygem, linkset: build(:linkset, docs: nil), versions: [version])
    links = rubygem.links(version)

    refute links.links.key?('home')
    assert links.links.key?('docs')
  end
end
