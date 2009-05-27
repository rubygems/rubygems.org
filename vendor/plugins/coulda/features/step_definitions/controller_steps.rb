When /^I generate a "(.*)" controller with "(.*)" action$/ do |controller, action|
  system "cd #{@rails_root} && " <<
         "script/generate controller #{controller} #{action} && " <<
         "cd .."
end

Then /^a standard "index" functional test for "(.*)" should be generated$/ do |controller|
  assert_generated_functional_test_for(controller) do |body|
    expected = "  context 'GET to index' do\n" <<
               "    setup { get :index }\n\n" <<
               "    should_respond_with :success\n" <<
               "    should_render_template :index\n" <<
               "  end"
    assert body.include?(expected), 
      "expected #{expected} but was #{body.inspect}"
  end
end

Then /^a standard "new" functional test for "posts" should be generated$/ do
  assert_generated_functional_test_for("posts") do |body|
    expected = "  context 'GET to new' do\n" <<
               "    setup { get :new }\n\n" <<
               "    should_respond_with :success\n" <<
               "    should_render_template :new\n" <<
               "    should_assign_to :post\n" <<
               "  end"
    assert body.include?(expected), 
      "expected #{expected} but was #{body.inspect}"
  end
end

Then /^a standard "create" functional test for "posts" should be generated$/ do
  assert_generated_functional_test_for("posts") do |body|
    expected = "  context 'POST to create with valid parameters' do\n" <<
               "    setup do\n" <<
               "      post :create, :post => Factory.attributes_for(:post)\n" <<
               "    end\n\n" <<
               "    should_change 'Post.count', :by => 1\n" <<
               "    should_set_the_flash_to /created/i\n" <<
               "    should_redirect_to('posts index') { posts_path }\n" <<
               "  end"
    assert body.include?(expected), 
      "expected #{expected} but was #{body.inspect}"
  end
end

Then /^a standard "show" functional test for "posts" should be generated$/ do
  assert_generated_functional_test_for("posts") do |body|
    expected = "  context 'GET to show for existing post' do\n" <<
               "    setup do\n" <<
               "      @post = Factory(:post)\n" <<
               "      get :show, :id => @post.to_param\n" <<
               "    end\n\n" <<
               "    should_respond_with :success\n" <<
               "    should_render_template :show\n" <<
               "    should_assign_to :post, :equals => '@post'\n" <<
               "  end"
    assert body.include?(expected), 
      "expected #{expected} but was #{body.inspect}"
  end
end

Then /^a standard "edit" functional test for "posts" should be generated$/ do
  assert_generated_functional_test_for("posts") do |body|
    expected = "  context 'GET to edit for existing post' do\n" <<
               "    setup do\n" <<
               "      @post = Factory(:post)\n" <<
               "      get :edit, :id => @post.to_param\n" <<
               "    end\n\n" <<
               "    should_respond_with :success\n" <<
               "    should_render_template :edit\n" <<
               "    should_assign_to :post, :equals => '@post'\n" <<
               "  end"
    assert body.include?(expected), 
      "expected #{expected} but was #{body.inspect}"
  end
end

Then /^a standard "update" functional test for "posts" should be generated$/ do
  assert_generated_functional_test_for("posts") do |body|
    expected = "  context 'PUT to update for existing post' do\n" <<
               "    setup do\n" <<
               "      @post = Factory(:post)\n" <<
               "      put :update, :id => @post.to_param,\n" <<
               "        :post => Factory.attributes_for(:post)\n" <<
               "    end\n\n" <<
               "    should_set_the_flash_to /updated/i\n" <<
               "    should_redirect_to('posts index') { posts_path }\n" <<
               "  end"
    assert body.include?(expected), 
      "expected #{expected} but was #{body.inspect}"
  end
end

Then /^a standard "destroy" functional test for "posts" should be generated$/ do
  assert_generated_functional_test_for("posts") do |body|
    expected = "  context 'given a post' do\n" <<
               "    setup { @post = Factory(:post) }\n\n" <<
               "    context 'DELETE to destroy' do\n" <<
               "      setup { delete :destroy, :id => @post.to_param }\n" <<
               "      should_change 'Post.count', :from => 1, :to => 0\n" <<
               "      should_set_the_flash_to /deleted/i\n" <<
               "      should_redirect_to('posts index') { posts_path }\n" <<
               "    end\n" <<
               "  end"
    assert body.include?(expected), 
      "expected #{expected} but was #{body.inspect}"
  end
end

Then /^a "new" controller action for "posts" should be generated$/ do
  assert_generated_controller_for("posts") do |body|
    expected = "  def new\n" <<
               "    @post = Post.new\n" <<
               "  end"
    assert body.include?(expected), 
      "expected #{expected} but was #{body.inspect}"
  end
end

Then /^a "create" controller action for "posts" should be generated$/ do
  assert_generated_controller_for("posts") do |body|
    expected = "  def create\n" <<
               "    @post = Post.new(params[:post])\n" <<
               "    @post.save\n" <<
               "    flash[:success] = 'Post created.'\n" <<
               "    redirect_to posts_path\n" <<
               "  end"
    assert body.include?(expected), 
      "expected #{expected} but was #{body.inspect}"
  end
end

Then /^a "show" controller action for "posts" should be generated$/ do
  assert_generated_controller_for("posts") do |body|
    expected = "  def show\n" <<
               "    @post = Post.find(params[:id])\n" <<
               "  end"
    assert body.include?(expected), 
      "expected #{expected} but was #{body.inspect}"
  end
end

Then /^a "edit" controller action for "posts" should be generated$/ do
  assert_generated_controller_for("posts") do |body|
    expected = "  def edit\n" <<
               "    @post = Post.find(params[:id])\n" <<
               "  end"
    assert body.include?(expected), 
      "expected #{expected} but was #{body.inspect}"
  end
end

Then /^a "update" controller action for "posts" should be generated$/ do
  assert_generated_controller_for("posts") do |body|
    expected = "  def update\n" <<
               "    @post = Post.find(params[:id])\n" <<
               "    @post.update_attributes(params[:post])\n" <<
               "    flash[:success] = 'Post updated.'\n" <<
               "    redirect_to posts_path\n" <<
               "  end"
    assert body.include?(expected), 
      "expected #{expected} but was #{body.inspect}"
  end
end

Then /^a "destroy" controller action for "posts" should be generated$/ do
  assert_generated_controller_for("posts") do |body|
    expected = "  def destroy\n" <<
               "    @post = Post.find(params[:id])\n" <<
               "    @post.destroy\n" <<
               "    flash[:success] = 'Post deleted.'\n" <<
               "    redirect_to posts_path\n" <<
               "  end"
    assert body.include?(expected), 
      "expected #{expected} but was #{body.inspect}"
  end
end

Then /^an empty "(.*)" controller action for "(.*)" should be generated$/ do |action, controller|
  assert_generated_controller_for(controller) do |body|
    assert_has_empty_method(body, action)
  end
end

