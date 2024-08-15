require "test_helper"

class Api::V1::ArchiveTest < ActionDispatch::IntegrationTest
  setup do
    @key = "12345"
    @user = create(:user)
    @rubygem = create(:rubygem)
    @ownership = create(:ownership, user: @user, rubygem: @rubygem)
    create(:api_key, owner: @user, key: @key, scopes: %i[archive_rubygem unarchive_rubygem])
  end

  context "on POST to create" do
    context "when the user is not authorized" do
      setup do
        post api_v1_rubygem_archive_path(@rubygem.name)
      end

      should "respond with HTTP 401" do
        assert_response :unauthorized
      end

      should "not archive the gem" do
        refute_predicate @rubygem, :archived?
      end
    end

    context "when the user is authenicated and authorized" do
      setup do
        post api_v1_rubygem_archive_path(@rubygem.name),
              headers: { HTTP_AUTHORIZATION: @key }
      end

      should "respond with HTTP 200" do
        assert_response :success
      end

      should "render a success message" do
        assert_equal "#{@rubygem.name} was succesfully archived.", response.body
      end
    end
  end

  context "on DELETE to destroy" do
    context "when the user is unauthenticated" do
      setup do
        delete api_v1_rubygem_archive_path(@rubygem.name)
      end

      should "respond with HTTP 401" do
        assert_response :unauthorized
      end

      should "not archive the gem" do
        assert_not @rubygem.archived?
      end
    end

    context "when the user is authenticated and authorized" do
      setup do
        delete api_v1_rubygem_archive_path(@rubygem.name),
            headers: { HTTP_AUTHORIZATION: @key }
      end

      should "respond with HTTP 200" do
        assert_response :success
      end

      should "unarchive the gem" do
        refute_predicate @rubygem, :archived?
      end

      should "render a success message" do
        assert_equal "#{@rubygem.name} was succesfully unarchived.", response.body
      end
    end
  end
end
