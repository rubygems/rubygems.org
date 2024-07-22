require "test_helper"

require "active_support/xml_mini/nokogiri"

class OIDC::TrustedPublisher::GitHubAction::TableComponentTest < ComponentTest
  should "render preview" do
    preview(repository_name: "rubygem2", workflow_filename: "push_gem.yml")

    assert_dl(
      lambda { |dt, dd|
        dt.assert_text "GitHub Repository", exact: true
        dd.assert_text "example/rubygem2", exact: true
      },
      lambda { |dt, dd|
        dt.assert_text "Workflow Filename", exact: true
        dd.assert_text "push_gem.yml", exact: true
      }
    )
  end

  def assert_dl(*rows, node: page)
    node.all("dl > *").each_slice(2) do |dt, dd|
      assert_equal "dt", dt.tag_name
      assert_equal "dd", dd.tag_name

      row = rows.shift

      flunk "Unexpected row: #{dt.text} => #{dd.text}" unless row
      row[dt, dd]
    end

    assert_empty rows
  end
end
