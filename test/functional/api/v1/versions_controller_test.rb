require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class Api::V1::VersionsControllerTest < ActionController::TestCase

  context "On GET to show with json for a gem that's hosted" do
    setup do
      @rubygem = Factory(:rubygem)
      Factory(:version, :rubygem => @rubygem)
      get :show, :rubygem_id => @rubygem.to_param, :format => "json"
    end

    should assign_to(:rubygem) { @rubygem }
    should respond_with :success
    should "return a json hash" do
      assert_not_nil JSON.parse(@response.body)
    end
  end

  context "On GET to show with xml for a gem that's hosted" do
    setup do
      @rubygem = Factory(:rubygem)
      Factory(:version, :rubygem => @rubygem)
      get :show, :rubygem_id => @rubygem.to_param, :format => "xml"
    end

    should assign_to(:rubygem) { @rubygem }
    should respond_with :success
    should "return a json hash" do
      assert_not_nil Nokogiri.parse(@response.body).root
    end
  end
  
end
