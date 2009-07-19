require 'test_helper'

class SearchesControllerTest < ActionController::TestCase

  context 'on GET to new with no search parameters' do
    setup { get :new }

    should_respond_with :success
    should_render_template :new
    should "see no results" do
      assert_not_contain "Results"
    end
  end
  
  context 'on GET to new with search parameters' do
    setup do
      @sinatra = Factory(:rubygem, :name => "sinatra")
      @brando  = Factory(:rubygem, :name => "brando")
      get :new, :query => "sinatra"
    end
    
    should_respond_with :success
    should_render_template :new
    should_assign_to(:gems) { [@sinatra] }
    should "see sinatra on the page in the results" do
      assert_contain "Results"
      assert_contain "sinatra"
      assert_have_selector "a[href='#{rubygem_path(@sinatra)}']"
    end
  end

end

