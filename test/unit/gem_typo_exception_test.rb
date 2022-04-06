require "test_helper"

class GemTypoExceptionTest < ActiveSupport::TestCase
  context "name validations" do
    should validate_uniqueness_of(:name).case_insensitive

    should "be a valid factory" do
      assert_predicate build(:gem_typo_exception), :valid?
    end

    should "be invalid with an empty string" do
      exception = build(:gem_typo_exception, name: "")
      refute_predicate exception, :valid?
    end

    should "be invalid when gem name exists" do
      create(:rubygem, name: "some")

      exception = build(:gem_typo_exception, name: "some")
      refute_predicate exception, :valid?
    end
  end
end
