require "test_helper"

class OIDC::TrustedPublisher::GitHubAction::FormComponentTest < ComponentTest
  should "render preview" do
    preview

    assert_field "Repository owner", with: "example"
    assert_field "Repository name", with: "rubygem2"
    assert_field "Workflow filename", with: "push_gem.yml"
    assert_field "Environment"
    assert_field "Workflow Repository Owner"
    assert_field "Workflow Repository Name"
  end
end
