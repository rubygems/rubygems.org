require "test_helper"

class Internal::PingControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      ActiveRecord::Base.connection.stubs(:select_value).returns(nil)
      get :index
    end

    should respond_with :success

    should "PONG" do
      assert page.has_content?("PONG")
    end
  end

  context "on GET to revision" do
    setup do
      @old_version = AppRevision.instance_variable_get(:@version)
      AppRevision.instance_variable_set(:@version, nil)
    end

    teardown do
      AppRevision.instance_variable_set(:@version, @old_version)
    end

    should "return revision from git" do
      f = mock
      f.expects(:read).raises(Errno::ENOENT)
      AppRevision.expects(:revision_file).returns(f)
      AppRevision.expects(:`).with("git rev-parse HEAD").returns("SOMESHAFROMGIT\n")

      get :revision
      assert_response :ok
      assert_equal "SOMESHAFROMGIT", @response.body
    end

    should "return revision from file" do
      AppRevision.stubs(revision_file: stub(read: "SOMESHA\n"))

      get :revision
      assert_response :ok
      assert_equal "SOMESHA", @response.body
    end
  end
end
