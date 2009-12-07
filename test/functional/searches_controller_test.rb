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

  context 'on GET to new with search parameters for a rubygem without versions' do
    setup do
      @sinatra = Factory(:rubygem, :name => "sinatra")
      assert_nil @sinatra.versions.latest
      assert @sinatra.reload.versions_count.zero?
      get :new, :query => "sinatra"
    end

    should_respond_with :success
    should_render_template :new
  end

  context 'on GET to new with search parameters' do
    setup do
      @sinatra = Factory(:rubygem, :name => "sinatra")
      @sinatra_redux = Factory(:rubygem, :name => "sinatra-redux")
      @brando  = Factory(:rubygem, :name => "brando")
      Factory(:version, :rubygem => @sinatra)
      Factory(:version, :rubygem => @sinatra_redux)
      Factory(:version, :rubygem => @brando)
      get :new, :query => "sinatra"
    end

    should_respond_with :success
    should_render_template :new
    should_assign_to(:gems) { [@sinatra, @sinatra_redux] }
    should_assign_to(:exact_match) { @sinatra }
    should "see sinatra on the page in the results" do
      assert_contain @sinatra.name
      assert_have_selector "a[href='#{rubygem_path(@sinatra)}']"
    end
    should "not see brando on the page in the results" do
      assert_not_contain @brando.name
      assert_have_no_selector "a[href='#{rubygem_path(@brando)}']"
    end
  end

end
