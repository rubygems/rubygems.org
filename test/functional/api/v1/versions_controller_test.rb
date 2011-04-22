require 'test_helper'

class Api::V1::VersionsControllerTest < ActionController::TestCase
  def get_show(rubygem)
    get :show, :id => "#{rubygem.name}.json"
  end

  context "on GET to show" do
    setup do
      @rubygem  = Factory(:rubygem)
      Factory(:version, :rubygem => @rubygem, :number => '1.0.0')
      Factory(:version, :rubygem => @rubygem, :number => '2.0.0')
      Factory(:version, :rubygem => @rubygem, :number => '3.0.0', :indexed => false)

      @rubygem2 = Factory(:rubygem)
      Factory(:version, :rubygem => @rubygem2, :number => '1.0.0')
      Factory(:version, :rubygem => @rubygem2, :number => '2.0.0')
      Factory(:version, :rubygem => @rubygem2, :number => '3.0.0')
    end

    should "have some json with the list of versions for the first gem" do
      get_show(@rubygem)
      assert_equal 2, JSON.parse(@response.body).size
    end

    should "have some json with the list of versions for the second gem" do
      get_show(@rubygem2)
      assert_equal 3, JSON.parse(@response.body).size
    end
  end

  context "on GET to show for an unknown gem" do
    setup do
      get :show, :id => "nonexistent_gem"
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This rubygem could not be found.", @response.body
    end
  end
end
