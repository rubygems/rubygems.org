# frozen_string_literal: true

require "test_helper"
require "rubocop"
require "rubocop/minitest/assert_offense"
require_relative "../../../lib/cops/repeated_nested_create"

class RuboCop::Cop::FactoryBot::RepeatedNestedCreateTest < ActiveSupport::TestCase
  include RuboCop::Minitest::AssertOffense

  test "registers an offense when a repeated create has a nested create" do
    assert_offense(<<~RUBY)
      3.times { create(:version, rubygem: create(:rubygem)) }
      ^^^^^^^ #{RuboCop::Cop::FactoryBot::RepeatedNestedCreate::MSG}
    RUBY

    assert_no_corrections
  end

  test "registers an offense for a do...end block" do
    assert_offense(<<~RUBY)
      2.times do
      ^^^^^^^ #{RuboCop::Cop::FactoryBot::RepeatedNestedCreate::MSG}
        create(:ownership, rubygem: create(:rubygem))
      end
    RUBY
  end

  test "registers an offense when the factory is called on FactoryBot" do
    assert_offense(<<~RUBY)
      3.times { FactoryBot.create(:version, rubygem: FactoryBot.create(:rubygem)) }
      ^^^^^^^ #{RuboCop::Cop::FactoryBot::RepeatedNestedCreate::MSG}
      3.times { ::FactoryBot.create(:version, rubygem: create(:rubygem)) }
      ^^^^^^^ #{RuboCop::Cop::FactoryBot::RepeatedNestedCreate::MSG}
    RUBY
  end

  test "registers an offense when the nested create is deeper in an argument" do
    assert_offense(<<~RUBY)
      3.times { create(:organization, memberships: [build(:membership, user: create(:user))]) }
      ^^^^^^^ #{RuboCop::Cop::FactoryBot::RepeatedNestedCreate::MSG}
    RUBY
  end

  test "does not register an offense when the block runs once" do
    assert_no_offenses(<<~RUBY)
      1.times { create(:version, rubygem: create(:rubygem)) }
    RUBY
  end

  test "does not register an offense when the count isn't a literal" do
    assert_no_offenses(<<~RUBY)
      count.times { create(:version, rubygem: create(:rubygem)) }
    RUBY
  end

  test "does not register an offense when the block uses its argument" do
    assert_no_offenses(<<~RUBY)
      3.times { |i| create(:version, number: "1.\#{i}.0", rubygem: create(:rubygem)) }
    RUBY
  end

  test "does not register an offense without a nested create" do
    assert_no_offenses(<<~RUBY)
      3.times { create(:rubygem) }
      3.times { create(:version, rubygem: rubygem) }
    RUBY
  end

  test "does not register an offense when the block body isn't a single create" do
    assert_no_offenses(<<~RUBY)
      3.times { build(:version, rubygem: create(:rubygem)) }
      3.times do
        rubygem = create(:rubygem)
        create(:version, rubygem: rubygem)
      end
    RUBY
  end

  test "does not register an offense for create on other receivers" do
    assert_no_offenses(<<~RUBY)
      3.times { Rubygem.create(:version, rubygem: create(:rubygem)) }
    RUBY
  end
end
