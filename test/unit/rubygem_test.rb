require File.dirname(__FILE__) + '/../test_helper'

class RubygemTest < ActiveSupport::TestCase
  should_belong_to :user
  should_have_many :versions
  should_have_many :dependencies

  should "be valid with factory" do
    assert_valid Factory.build(:rubygem)
  end

end
