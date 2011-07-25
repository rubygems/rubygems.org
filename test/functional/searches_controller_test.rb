require 'test_helper'

class SearchesControllerTest < ActionController::TestCase

  context 'on GET to show with no search parameters' do
    setup { get :show }

    should respond_with :success
    should render_template :show
    should "see no results" do
      assert ! page.has_content?("Results")
    end
  end

  context 'on GET to show with search parameters for a rubygem without versions' do
    setup do
      @sinatra = Factory(:rubygem, :name => "sinatra")
      assert_nil @sinatra.versions.most_recent
      assert @sinatra.reload.versions.count.zero?
      get :show, :query => "sinatra"
    end

    should respond_with :success
    should render_template :show
  end

  context 'on GET to show with search parameters' do
    setup do
      @sinatra = Factory(:rubygem, :name => "sinatra")
      @sinatra_redux = Factory(:rubygem, :name => "sinatra-redux")
      @brando  = Factory(:rubygem, :name => "brando")
      Factory(:version, :rubygem => @sinatra)
      Factory(:version, :rubygem => @sinatra_redux)
      Factory(:version, :rubygem => @brando)
      get :show, :query => "sinatra"
    end

    should respond_with :success
    should render_template :show
    should assign_to(:gems) { [@sinatra, @sinatra_redux] }
    should assign_to(:exact_match) { @sinatra }
    should "see sinatra on the page in the results" do
      assert page.has_content?(@sinatra.name)
      assert page.has_selector?("a[href='#{rubygem_path(@sinatra)}']")
    end
    should "not see brando on the page in the results" do
      assert ! page.has_content?(@brando.name)
      assert ! page.has_selector?("a[href='#{rubygem_path(@brando)}']")
    end
  end
end
