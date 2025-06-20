require "test_helper"

class LinksetTest < ActiveSupport::TestCase
  should belong_to :rubygem

  context "with a linkset" do
    setup do
      @linkset = build(:linkset)
    end

    should "be valid with factory" do
      assert_predicate @linkset, :valid?
    end

    should "not be empty with some links filled out" do
      refute_empty @linkset
    end

    should "be empty with no links filled out" do
      Linkset::LINKS.each do |link|
        @linkset.send(:"#{link}=", nil)
      end

      assert_empty @linkset
    end
  end

  context "validations" do
    %w[home code docs wiki mail bugs].each do |link|
      should allow_value("http://example.com").for(link.to_sym)
      should validate_length_of(link).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
    end
  end
end
