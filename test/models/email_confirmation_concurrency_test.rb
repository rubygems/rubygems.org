# frozen_string_literal: true

require "test_helper"

class EmailConfirmationConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @user = create(:user, email: "old-#{SecureRandom.hex(4)}@rubygems-test.org")
    @user.update!(unconfirmed_email: "new-#{SecureRandom.hex(4)}@rubygems-test.org")
    @target = @user.unconfirmed_email
    @token = @user.issue_email_confirmation!(@target)
  end

  teardown do
    Events::UserEvent.where(user: @user).delete_all
    @user.delete
  end

  test "only one concurrent consumer confirms a token" do
    results = Queue.new
    ready = Queue.new
    start = Queue.new

    threads = Array.new(2) do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          user = User.find(@user.id)
          ready << true
          start.pop
          results << user.confirm_email_with_token(@token)
        end
      end
    end

    2.times { ready.pop }
    2.times { start << true }
    threads.each(&:join)

    assert_equal %i[confirmed invalid_token], Array.new(2) { results.pop }.sort
    assert_equal @target, @user.reload.email
    assert_nil @user.unconfirmed_email
    assert_nil @user.email_confirmation_token_digest
  end
end
