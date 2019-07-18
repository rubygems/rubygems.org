require "test_helper"

class MailerTest < ActionMailer::TestCase
  test "gem pushed mail will only send to owner with enabled notifier" do
    owner_without_notifier, owner_with_notifier = owners = create_list(:user, 2)
    rubygem = create(:rubygem, owners: owners, number: "0.1.2")
    owner_without_notifier.ownerships.update_all(notifier: false)

    message_delivery = Mailer.gem_pushed(owner_without_notifier.id, rubygem.versions.last.id)

    assert_instance_of Mail::Message, message_delivery.message
    assert_equal [owner_with_notifier.email], message_delivery.to
  end

  test "gem pushed mail will not send when all owners disable notifiers" do
    owners = create_list(:user, 2)
    rubygem = create(:rubygem, owners: owners, number: "0.1.2")
    Ownership.update_all(notifier: false)

    message_delivery = Mailer.gem_pushed(owners.first.id, rubygem.versions.last.id)

    assert_instance_of ActionMailer::Base::NullMail, message_delivery.message
  end
end
