require "test_helper"

class ReverseDependenciesControllerTest < ActionController::TestCase
  context "On GET to show for a gem reverse dependencies" do
    setup do
      @version_one = create(:version)
      @rubygem_one = @version_one.rubygem
      @version_two = create(:version)
      @rubygem_two = @version_two.rubygem
      @version_three = create(:version)
      @rubygem_three = @version_three.rubygem
      @version_four = create(:version)
      @rubygem_four = @version_four.rubygem

      @version_two.dependencies << create(:dependency,
        version: @version_two,
        rubygem: @rubygem_one)
      @version_three.dependencies << create(:dependency,
        version: @version_three,
        rubygem: @rubygem_two)
      @version_four.dependencies << create(:dependency,
        version: @version_four,
        rubygem: @rubygem_two)
    end

    context "render template" do
      setup do
        get :index, params: { rubygem_id: @rubygem_one.slug }
      end

      should respond_with :success
      should render_template :index
    end

    should "show reverse dependencies" do
      get :index, params: { rubygem_id: @rubygem_one.slug }

      assert page.has_content?(@rubygem_two.name)
      refute page.has_content?(@rubygem_three.name)

      form_path = rubygem_reverse_dependencies_path(@rubygem_one.slug)
      assert page.has_selector?("form#rdeps-search[action='#{form_path}']")
    end

    should "search reverse dependencies" do
      get :index,
        params: {
          rubygem_id: @rubygem_two.slug,
          rdeps_query: @rubygem_three.name
        }

      assert page.has_content?(@rubygem_three.name)
      refute page.has_content?(@rubygem_four.name)
    end

    should "search only current reverse dependencies" do
      get :index,
        params: {
          rubygem_id: @rubygem_two.slug,
          rdeps_query: @rubygem_one.name
        }

      refute page.has_content?(@rubygem_one.name)
    end
  end
end
