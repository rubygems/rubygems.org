# frozen_string_literal: true

require "test_helper"

class Avo::SponsorsTest < ActionDispatch::IntegrationTest
  include AdminHelpers
  include ActiveJob::TestHelper

  setup do
    @storage_root = ActiveStorage::Blob.service.root
    @test_storage_root = Dir.mktmpdir("sponsor-logos")
    ActiveStorage::Blob.service.root = @test_storage_root
    @admin = create(:admin_github_user, :is_admin)
    @sponsor = Sponsor.create!(name: "Private", tier: :supporter_plus, anonymous: true)
    @sponsor.logo.attach(io: StringIO.new(File.binread(logo_path)), filename: "private.png", content_type: "image/png")
  end

  teardown do
    ActiveStorage::Blob.service.root = @storage_root
    FileUtils.remove_entry @test_storage_root
  end

  test "audited multipart create, replace, reorder, visibility action and destroy" do
    admin_sign_in_as @admin
    get "/admin/resources/sponsors/new"

    assert_response :success
    assert_select "input[type=file][name='sponsor[logo]']"

    assert_difference ["Sponsor.count", "ActiveStorage::Blob.count", "ActiveStorage::Attachment.count", "Audit.count"] do
      post "/admin/resources/sponsors", params: { sponsor: attributes.merge(logo: upload) }
    end
    sponsor = Sponsor.find_by!(name: "Uploaded")

    assert_redirected_to avo.resources_audit_path(Audit.last)
    assert_equal @admin, Audit.last.admin_github_user
    assert_equal sponsor, Audit.last.auditable
    assert_equal File.binread(logo_path), sponsor.logo.download

    get "/admin/resources/sponsors/#{sponsor.id}/edit"

    assert_response :success
    assert_select "img[src*='/sponsor_logos/']"

    old_blob = sponsor.logo.blob
    assert_difference "Audit.count" do
      patch "/admin/resources/sponsors/#{sponsor.id}",
params: { sponsor: { position: 17, logo: upload, comment: "Replace the sponsor logo and order" } }
    end
    assert_redirected_to avo.resources_audit_path(Audit.last)
    assert_equal 17, sponsor.reload.position
    refute_equal old_blob.id, sponsor.logo.blob.id
    assert_equal File.binread(logo_path), sponsor.logo.download

    assert_difference "Audit.count" do
      visibility_action(sponsor, true)
    end
    assert_response :success
    assert_predicate sponsor.reload, :show_in_footer?
    assert_equal "Set Sponsor Footer Visibility", Audit.last.action
    assert_equal @admin, Audit.last.admin_github_user

    assert_difference "Audit.count" do
      post "/admin/resources/sponsors/#{sponsor.id}/actions", params: {
        action_id: "Avo::Actions::SetSponsorCategory", resource_view: "show",
        fields: { avo_resource_ids: sponsor.id.to_s, tier: "open_source", comment: "Move to the open source category" }
      }, as: :turbo_stream
    end
    assert_response :success
    assert_equal "open_source", sponsor.reload.tier
    assert_equal sponsor, Audit.last.auditable

    assert_difference "Sponsor.count", -1 do
      assert_difference "Audit.count" do
        delete "/admin/resources/sponsors/#{sponsor.id}", as: :turbo_stream
      end
    end
    assert_redirected_to "/admin/resources/sponsors"
    assert_equal "Manual destroy of Sponsor", Audit.last.action
    assert_equal 5, Audit.where(auditable_type: "Sponsor", auditable_id: sponsor.id).count
  end

  test "denied writes and uploads leave no rows, storage files, jobs or changes" do
    outsider = create(:admin_github_user, :is_admin)
    info_data = outsider.info_data.deep_dup
    info_data[:viewer][:organization][:teams][:edges].reject! { |edge| edge.dig(:node, :slug) == "rubygems-org" }
    outsider.update!(info_data:)

    [nil, outsider].each do |user|
      cookies.delete("rubygems_admin_oauth_github_user")
      admin_sign_in_as user if user
      state = @sponsor.reload.attributes
      assert_no_upload_changes do
        post "/admin/resources/sponsors", params: { sponsor: attributes.merge(logo: upload) }
        user ? assert_redirected_to(avo.root_path) : assert_response(:success)
        patch "/admin/resources/sponsors/#{@sponsor.id}", params: { sponsor: attributes.merge(logo: upload) }
        user ? assert_redirected_to(avo.root_path) : assert_response(:success)
        delete "/admin/resources/sponsors/#{@sponsor.id}"
        user ? assert_redirected_to(avo.root_path) : assert_response(:success)
        visibility_action(@sponsor, true)
        user ? assert_redirected_to(avo.root_path) : assert_response(:success)
        delete "/admin/resources/sponsors/#{@sponsor.id}/active_storage_attachments/logo/#{@sponsor.logo.attachment.id}", as: :turbo_stream
        user ? assert_response(:not_found) : assert_response(:success)
      end
      assert_equal state, @sponsor.reload.attributes
    end
  end

  test "missing audit comment and SVG upload cannot write" do
    admin_sign_in_as @admin
    assert_no_upload_changes do
      post "/admin/resources/sponsors", params: { sponsor: attributes.except(:comment).merge(logo: upload) }

      assert_response :unprocessable_entity
      svg = Rack::Test::UploadedFile.new(Rails.root.join("app/assets/images/supporters/cloudamqp-dark.svg"), "image/png")
      post "/admin/resources/sponsors", params: { sponsor: attributes.merge(logo: svg) }

      assert_response :unprocessable_entity
      assert_includes response.body, "must be PNG or WebP"

      post "/admin/resources/sponsors", params: { sponsor: attributes.merge(logo: @sponsor.logo.blob.signed_id) }

      assert_response :unprocessable_entity

      post "/admin/resources/sponsors/#{@sponsor.id}/actions", params: {
        action_id: "Avo::Actions::SetSponsorFooterVisibility", resource_view: "show",
        fields: { avo_resource_ids: @sponsor.id.to_s, show_in_footer: true }
      }, as: :turbo_stream

      assert_response :success
      assert_includes response.body, "Must supply a sufficiently detailed comment"
    end
    refute_predicate @sponsor.reload, :show_in_footer?
  end

  test "all direct and unaudited attachment upload routes are blocked even for admins" do
    [nil, @admin].each do |user|
      cookies.delete("rubygems_admin_oauth_github_user")
      admin_sign_in_as user if user
      assert_no_upload_changes do
        assert_raises(ActionController::RoutingError) { post "/rails/active_storage/direct_uploads", params: { blob: { filename: "logo.png" } } }
        post "/admin/rails/active_storage/direct_uploads", params: { blob: { filename: "logo.png" } }
        user ? assert_response(:not_found) : assert_response(:success)
        post "/admin/avo_api/resources/sponsors/#{@sponsor.id}/attachments", params: { attachment_key: "logo", filename: "logo.png", file: upload }
        user ? assert_response(:not_found) : assert_response(:success)
      end
    end
  end

  private

  def logo_path = Rails.root.join("app/assets/images/sponsors/aws.png")
  def upload = Rack::Test::UploadedFile.new(logo_path, "image/png")

  def attributes
    { name: "Uploaded", tier: "infrastructure", website_url: "https://example.org", position: 3, comment: "Add this new public sponsor" }
  end

  def visibility_action(sponsor, visible)
    post "/admin/resources/sponsors/#{sponsor.id}/actions", params: {
      action_id: "Avo::Actions::SetSponsorFooterVisibility", resource_view: "show",
      fields: { avo_resource_ids: sponsor.id.to_s, show_in_footer: visible, comment: "Update public footer visibility" }
    }, as: :turbo_stream
  end

  def assert_no_upload_changes(&block)
    files = storage_files
    assert_no_enqueued_jobs do
      assert_no_difference ["Sponsor.count", "ActiveStorage::Blob.count", "ActiveStorage::Attachment.count", "Audit.count", "GoodJob::Job.count"],
&block
    end
    assert_equal files, storage_files
  end

  def storage_files
    Dir.glob("#{@test_storage_root}/**/*").select { |path| File.file?(path) }.index_with { |path| Digest::SHA256.file(path).hexdigest }
  end
end
