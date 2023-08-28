require "test_helper"
require "helpers/adoption_helpers"

class OwnershipRequestsTest < SystemTest
  include ActionMailer::TestHelper
  include AdoptionHelpers

  setup do
    @owner = create(:user)
  end

  test "create ownership request" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    user = create(:user)
    create(:ownership_call, rubygem: rubygem)
    visit ownership_calls_path(as: user.id)
    click_link "Apply"

    fill_in "Note", with: "request has _italics_ with *bold*."
    click_button "Create ownership request"

    within all("div.ownership__details")[1] do
      assert page.has_css? "em", text: "italics"
      assert page.has_css? "strong", text: "bold"
    end
    assert page.has_button? "Close"
    refute page.has_button? "Approve"
  end

  test "approve ownership request by owner" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    user = create(:user)
    create(:ownership_call, rubygem: rubygem)
    create(:ownership_request, user: user, rubygem: rubygem)

    visit_rubygem_adoptions_path(rubygem, @owner)

    click_button "Approve"

    assert_enqueued_emails 3
    assert_includes(rubygem.owners, user)
  end

  test "close ownership request by requester" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    user = create(:user)
    create(:ownership_call, rubygem: rubygem)
    create(:ownership_request, user: user, rubygem: rubygem)

    visit rubygem_adoptions_path(rubygem.slug, as: user.id)

    click_button "Close"

    assert_empty rubygem.ownership_requests
    assert_enqueued_emails 0
  end

  test "close ownership request by owner" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    user = create(:user)
    create(:ownership_call, rubygem: rubygem)
    create(:ownership_request, user: user, rubygem: rubygem)

    visit_rubygem_adoptions_path(rubygem, @owner)

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      page.find_by_id("owner_close_request").click
    end

    assert_empty rubygem.ownership_requests
    assert_emails 1
    assert_equal "Your ownership request was closed.", last_email.subject
  end

  test "cannot close all requests as user" do
    rubygem = create(:rubygem, owners: [@owner], downloads: 2_000)
    create(:version, rubygem: rubygem, created_at: 2.years.ago)
    user = create(:user)
    create_list(:ownership_request, 3, rubygem: rubygem)

    visit rubygem_adoptions_path(rubygem.slug, as: user.id)

    refute page.has_link? "Close all"
  end

  test "close all requests as owner" do
    rubygem = create(:rubygem, owners: [@owner], downloads: 2_000)
    create(:version, rubygem: rubygem, created_at: 2.years.ago)
    create_list(:ownership_request, 3, rubygem: rubygem)

    visit_rubygem_adoptions_path(rubygem, @owner)

    click_button "Close all"
    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

    assert_emails 3
  end
end
