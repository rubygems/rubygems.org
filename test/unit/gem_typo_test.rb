require "test_helper"

class GemTypoTest < ActiveSupport::TestCase
  context "with above downloads threshold gem" do
    setup do
      create(:rubygem, :protected, name: "four")
    end

    should "return false for exact match" do
      gem_typo = GemTypo.new("four")
      assert_equal false, gem_typo.protected_typo?
    end

    should "return false for gem name size below protected threshold" do
      gem_typo = GemTypo.new("fou")
      assert_equal false, gem_typo.protected_typo?
    end

    context "size equals protected threshold" do
      should "return true for one character distance" do
        gem_typo = GemTypo.new("fous")
        assert_equal true, gem_typo.protected_typo?
      end

      should "return false for two character distance" do
        gem_typo = GemTypo.new("foss")
        assert_equal false, gem_typo.protected_typo?
      end
    end

    context "size above protected threshold" do
      should "return true for two character distance" do
        gem_typo = GemTypo.new("fourss")
        assert_equal true, gem_typo.protected_typo?
      end

      should "return false for exceptions" do
        create(:gem_typo_exception, name: "fourss")

        gem_typo = GemTypo.new("fourss")
        assert_equal false, gem_typo.protected_typo?
      end

      should "return false for three characher distance" do
        gem_typo = GemTypo.new("foursss")
        assert_equal false, gem_typo.protected_typo?
      end
    end
  end
end
