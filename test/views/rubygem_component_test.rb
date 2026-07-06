# frozen_string_literal: true

require "test_helper"

class RubygemComponentTest < ComponentTest
  include Rails.application.routes.url_helpers

  setup do
    @rubygem = create(:rubygem, name: "my-gem", number: "1.2.3", downloads: 42_000).reload
  end

  should "link to the rubygem page" do
    render RubygemComponent.new(rubygem: @rubygem)

    assert_link href: rubygem_path(id: @rubygem.name)
  end

  should "display the gem name" do
    render RubygemComponent.new(rubygem: @rubygem)

    assert_selector "h2", text: "my-gem"
  end

  should "display the version badge" do
    render RubygemComponent.new(rubygem: @rubygem)

    assert_selector "code", text: "1.2.3"
  end

  should "display the download count" do
    render RubygemComponent.new(rubygem: @rubygem)

    assert_text "42,000"
  end

  should "display the gem description" do
    render RubygemComponent.new(rubygem: @rubygem)

    assert_text view_context.short_info(@rubygem)
  end

  should "not display a version badge when the version number is absent" do
    @rubygem.latest_version.stubs(:number).returns(nil)
    render RubygemComponent.new(rubygem: @rubygem)

    refute_selector "code"
  end
end
