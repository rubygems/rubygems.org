# frozen_string_literal: true

require "test_helper"

class StaticPagesManifestTest < ActionDispatch::IntegrationTest
  test "configured static pages have templates and titles" do
    Gemcutter::PAGES.each do |page|
      assert_template_exists "pages", page
      assert I18n.exists?("pages.#{page}.title"), "missing title for pages.#{page}"
    end
  end

  test "configured policy pages have templates and titles" do
    Gemcutter::POLICY_PAGES.each do |policy|
      assert_template_exists "policies", policy
      assert I18n.exists?("policies.#{policy}.title"), "missing title for policies.#{policy}"
    end
  end

  test "configured policy markdown pages render" do
    Gemcutter::POLICY_PAGES.each do |policy|
      get policy_path(policy)

      assert_response :success
      assert_select "main"
    end
  end

  private

  def assert_template_exists(directory, page)
    pattern = Rails.root.join("app/views/#{directory}/#{page}.*")

    assert_predicate Dir.glob(pattern.to_s), :any?, "missing template for #{directory}/#{page}"
  end
end
