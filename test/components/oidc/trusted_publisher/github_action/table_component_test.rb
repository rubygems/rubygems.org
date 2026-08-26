# frozen_string_literal: true

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

  should "render preview with workflow repository" do
    preview(repository_name: "my-gem", workflow_filename: "shared-release.yml",
            workflow_repository_owner: "shared-org", workflow_repository_name: "shared-workflows")

    assert_dl(
      lambda { |dt, dd|
        dt.assert_text "GitHub Repository", exact: true
        dd.assert_text "example/my-gem", exact: true
      },
      lambda { |dt, dd|
        dt.assert_text "Workflow Filename", exact: true
        dd.assert_text "shared-release.yml", exact: true
      },
      lambda { |dt, dd|
        dt.assert_text "Workflow Repository", exact: true
        dd.assert_text "shared-org/shared-workflows", exact: true
      }
    )
  end

  def assert_dl(*rows, node: page)
    # rubocop:disable Rails/FindEach
    node.all("dl > div").each do |row_node|
      dt = row_node.find("dt")
      dd = row_node.find("dd")

      row = rows.shift

      flunk "Unexpected row: #{dt.text} => #{dd.text}" unless row
      row[dt, dd]
    end
    # rubocop:enable Rails/FindEach

    assert_empty rows
  end
end
