require "test_helper"

class AdoptionsTest < SystemTest
  include EmailHelpers
  include ProfileHelpers

  setup do
    @user = create(:user, handle: "nick1")
    @rubygem = create(:rubygem)
  end

  test "listing gem with no open adoptions and no signed in user" do
    visit rubygem_adoptions_path(@rubygem)
    assert page.has_content? "Owner(s) of #{@rubygem.name} are not looking for maintainers."
    assert page.has_link?("Sign in", href: "/sign_in")
  end

  test "opening adoption by owner" do
    @rubygem.ownerships.create(user: @user)
    sign_in @user

    visit rubygem_adoptions_path(@rubygem)
    fill_in "Note", with: "example note"
    click_button "Open"

    assert page.has_content? "example note"
    assert page.has_selector? "#flash_success", text: "#{@rubygem.name} has been put up for adoption"
  end

  test "requesting adoption" do
    owner = create(:user)
    @rubygem.ownerships.create(user: owner)
    sign_in @user

    visit rubygem_adoptions_path(@rubygem)
    fill_in "Note", with: "example note"
    click_button "Request"

    mail = last_email
    assert mail.to.include? owner.email
    expected_subject = "Adoption request for #{@rubygem.name}"
    assert_equal expected_subject, mail.subject
    expected_body = "#{@user.name} has requested adoption of #{@rubygem.name}"
    assert mail.to_s.include? expected_body

    assert page.has_content? "example note"
    assert page.has_selector? "#flash_success", text: "Adoption request sent to owner(s) of #{@rubygem.name}"
  end

  test "canceling adoption by requester" do
    create(:adoption, rubygem: @rubygem, user: @user, note: "example note")
    sign_in @user

    visit rubygem_adoptions_path(@rubygem)
    click_button "Cancel"

    assert page.has_selector? "#flash_success", text: "#{@user.name}'s adoption request for #{@rubygem.name} has been canceled"
    assert page.has_no_content? "example note"
  end

  test "canceling adoption by owner" do
    adoption = create(:adoption, rubygem: @rubygem, note: "example note")
    @rubygem.ownerships.create(user: @user)
    sign_in @user

    visit rubygem_adoptions_path(@rubygem)
    click_button "Cancel"

    mail = last_email
    assert mail.to.include? adoption.user.email
    expected_subject = "Adoption request rejected for #{@rubygem.name}"
    assert_equal expected_subject, mail.subject
    expected_body = "We are sorry to tell you that your request for adoption of #{@rubygem.name} has been rejected."
    assert mail.to_s.include? expected_body

    assert page.has_selector? "#flash_success", text: "#{adoption.user.name}'s adoption request for #{@rubygem.name} has been canceled"
    assert page.has_no_content? "example note"
  end

  test "approving adoption by owner" do
    adoption = create(:adoption, rubygem: @rubygem, note: "example note")
    @rubygem.ownerships.create(user: @user)
    sign_in @user

    visit rubygem_adoptions_path(@rubygem)
    click_button "Approve"

    mail = last_email
    assert mail.to.include? adoption.user.email
    expected_subject = "Adoption request approved for #{@rubygem.name}"
    assert_equal expected_subject, mail.subject

    assert page.has_selector? "#flash_success", text: "#{adoption.user.name}'s adoption request for #{@rubygem.name} has been approved"
    assert page.has_no_content? "example note"
    assert @rubygem.owned_by? adoption.user
  end
end
