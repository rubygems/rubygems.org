require 'test_helper'

class MigrationsControllerTest < ActionController::TestCase
  context "with a rubygem" do
    setup do
      @rubygem = Factory(:rubygem)
    end
    should_forbid_access_when("starting the migration") { post :create, :rubygem_id => @rubygem }
  end
end

