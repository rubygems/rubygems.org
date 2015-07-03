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
      @sinatra = create(:rubygem, name: "sinatra")
      assert_nil @sinatra.versions.most_recent
      assert @sinatra.reload.versions.count.zero?
      get :show, query: "sinatra"
    end

    should respond_with :success
    should render_template :show
  end

  context 'on GET to show with search parameters' do
    setup do
      @sinatra = create(:rubygem, name: "sinatra")
      @sinatra_redux = create(:rubygem, name: "sinatra-redux")
      @brando  = create(:rubygem, name: "brando")
      create(:version, rubygem: @sinatra)
      create(:version, rubygem: @sinatra_redux)
      create(:version, rubygem: @brando)
      get :show, query: "sinatra"
    end

    should respond_with :success
    should render_template :show
    should "see sinatra on the page in the results" do
      assert page.has_content?(@sinatra.name)
      assert page.has_selector?("a[href='#{rubygem_path(@sinatra)}']")
    end
    should "not see brando on the page in the results" do
      assert ! page.has_content?(@brando.name)
      assert ! page.has_selector?("a[href='#{rubygem_path(@brando)}']")
    end
    should "display 'gems' in pagination summary" do
      assert page.has_content?("all 2 gems")
    end
  end

  context 'on GET to show with search parameters with a single exact match' do
    setup do
      @sinatra = create(:rubygem, name: "sinatra")
      create(:version, rubygem: @sinatra)
      get :show, query: "sinatra"
    end

    should respond_with :redirect
    should redirect_to('the gem') { rubygem_path(@sinatra) }
  end

  context 'on GET to show with non string search parameter' do
    setup do
      get :show, query: { foo: "bar" }
    end

    should respond_with :success
    should render_template :show
  end
end
