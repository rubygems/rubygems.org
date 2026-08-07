# frozen_string_literal: true

require "test_helper"

class Avo::Resources::UserTest < ActiveSupport::TestCase
  SEARCH_COLUMNS = %w[email blocked_email handle].freeze

  test "search finds users by active and blocked email case-insensitively" do
    active_user = create(:user, email: "Active-User@rubygems-test.org")
    blocked_user = create(:user, :blocked, blocked_email: "Blocked-User@rubygems-test.org")

    assert_equal [active_user], search("active-user")
    assert_equal [blocked_user], search("blocked-user")
  end

  test "search requires at least three characters" do
    user = create(:user, email: "responsive-search@rubygems-test.org")

    assert_empty search("")
    assert_empty search("re")
    assert_equal [user], search("res")
  end

  test "search columns use trigram indexes" do
    indexes = ActiveRecord::Base.connection.indexes(:users).index_by(&:name)

    SEARCH_COLUMNS.each do |column|
      index = indexes.fetch("index_users_on_#{column}_trigram")

      assert_equal [column], index.columns
      assert_equal :gin, index.using
      assert_equal :gin_trgm_ops, index.opclasses
    end
    assert_equal "(blocked_email IS NOT NULL)", indexes.fetch("index_users_on_blocked_email_trigram").where
  end

  test "search query can use every trigram index" do
    connection = ActiveRecord::Base.connection
    connection.execute("SET enable_seqscan = off")

    plan = connection.select_values("EXPLAIN #{search_relation('blocked-user').to_sql}").join("\n")

    SEARCH_COLUMNS.each do |column|
      assert_includes plan, "Bitmap Index Scan on index_users_on_#{column}_trigram"
    end
  ensure
    connection&.execute("RESET enable_seqscan")
  end

  private

  def search(term)
    search_relation(term).to_a
  end

  def search_relation(term)
    Avo::ExecutionContext.new(
      target: Avo::Resources::User.search_query,
      params: { q: term },
      query: User.all,
      q: term
    ).handle
  end
end
