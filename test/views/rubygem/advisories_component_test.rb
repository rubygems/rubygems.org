# frozen_string_literal: true

require "test_helper"

class Rubygem::AdvisoriesComponentTest < ComponentTest
  def render_page(component)
    Capybara.string(render(component))
  end

  def advisory(**attrs)
    build(:advisory, :unfixed, **attrs)
  end

  should "render nothing when there are no affected advisories" do
    page = render_page Rubygem::AdvisoriesComponent.new(
      advisories: [advisory(ranges: ["introduced" => "2.0.0"])],
      version: build(:version, number: "1.0.0")
    )

    refute page.has_css?("[data-testid='gem-advisories']")
  end

  should "render nothing when advisories are empty" do
    page = render_page Rubygem::AdvisoriesComponent.new(advisories: [], version: build(:version, number: "1.0.0"))

    refute page.has_css?("[data-testid='gem-advisories']")
  end

  should "render advisory details and a link" do
    advisory = advisory(
      identifier: "GHSA-mm33-5vfq-3mm3",
      aliases: ["CVE-2022-22577"],
      summary: "Cross-site Scripting Vulnerability",
      severity: :moderate,
      url: "https://osv.dev/vulnerability/GHSA-mm33-5vfq-3mm3"
    )
    page = render_page Rubygem::AdvisoriesComponent.new(
      advisories: [advisory],
      version: build(:version, number: "1.0.0")
    )

    assert page.has_css?("[data-testid='gem-advisories']")
    assert page.has_text?("1 known security vulnerability")
    assert page.has_text?("moderate")
    assert page.has_text?("GHSA-mm33-5vfq-3mm3")
    assert page.has_text?("CVE-2022-22577")
    assert page.has_text?("Cross-site Scripting Vulnerability")
    assert page.has_link?("View advisory", href: "https://osv.dev/vulnerability/GHSA-mm33-5vfq-3mm3")
    assert page.has_css?(".bg-yellow-200")
  end

  should "use the error style when a high or critical advisory is present" do
    page = render_page Rubygem::AdvisoriesComponent.new(
      advisories: [advisory(severity: :critical), advisory(severity: :moderate)],
      version: build(:version, number: "1.0.0")
    )

    assert page.has_css?(".bg-red-200")
    assert page.has_text?("2 known security vulnerabilities")
  end

  should "sort advisories by severity" do
    page = render_page Rubygem::AdvisoriesComponent.new(
      advisories: [
        advisory(identifier: "GHSA-loww-0000-0001", severity: :low),
        advisory(identifier: "GHSA-crit-0000-0001", severity: :critical),
        advisory(identifier: "GHSA-high-0000-0001", severity: :high)
      ],
      version: build(:version, number: "1.0.0")
    )

    text = page.text

    assert_operator text.index("GHSA-crit-0000-0001"), :<, text.index("GHSA-high-0000-0001")
    assert_operator text.index("GHSA-high-0000-0001"), :<, text.index("GHSA-loww-0000-0001")
  end
end
