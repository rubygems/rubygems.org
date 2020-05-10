require "test_helper"
require "capybara/minitest"

class NotificationSettingsTest < SystemTest
  include Capybara::Minitest::Assertions

  test "changing email notification settings" do
    user = create(:user)
    rubygem1 = create(:rubygem, number: "0.0.1")
    rubygem2 = create(:rubygem, number: "0.0.2")
    ownership1 = create(:ownership, rubygem: rubygem1, user: user)
    ownership2 = create(:ownership, rubygem: rubygem2, user: user)

    visit edit_profile_path(as: user)

    click_link I18n.t("notifiers.show.title")

    notifier_form_selector = "form[action='/notifier']"

    within_element notifier_form_selector do
      assert_checked_field notifier_on_radio(ownership1)
      assert_unchecked_field notifier_off_radio(ownership1)
      assert_checked_field notifier_on_radio(ownership2)
      assert_unchecked_field notifier_off_radio(ownership2)

      choose notifier_off_radio(ownership1)

      click_button I18n.t("notifiers.show.update")
    end

    assert_changes :mails_count, from: 0, to: 1 do
      Delayed::Worker.new.work_off
    end

    assert_equal I18n.t("mailer.notifiers_changed.subject"), last_email.subject

    assert_selector "#flash_notice", text: I18n.t("notifiers.update.success")

    within_element notifier_form_selector do
      assert_unchecked_field notifier_on_radio(ownership1)
      assert_checked_field notifier_off_radio(ownership1)
      assert_checked_field notifier_on_radio(ownership2)
      assert_unchecked_field notifier_off_radio(ownership2)
    end
  end

  test "email notification settings not shown to user who owns no gems" do
    user = create(:user)

    visit edit_profile_path(as: user)

    assert_no_text I18n.t("notifiers.show.title")
  end

  test "email notification setting does not show for yanked gems" do
    user = create(:user)
    create(:rubygem, number: "0.0.1", owners: [user])

    yanked_rubygem = create(:rubygem, name: "yanked-gem", owners: [user])
    create(:version, rubygem: yanked_rubygem, indexed: false)

    visit edit_profile_path(as: user)

    click_link I18n.t("notifiers.show.title")

    assert_no_text "yanked-gem"
  end

  def notifier_on_radio(ownership)
    "ownerships_#{ownership.id}_on"
  end

  def notifier_off_radio(ownership)
    "ownerships_#{ownership.id}_off"
  end
end
