require "test_helper"

class UsersHelperTest < ActionView::TestCase
  context "obfuscate_email" do
    should "obfuscate standard email" do
      assert_equal "g*******@e******.com", obfuscate_email("gem-user@example.com")
    end

    should "obfuscate email with short local part" do
      assert_equal "j**@g****.com", obfuscate_email("joe@gmail.com")
    end

    should "handle very short email parts" do
      assert_equal "j@x.io", obfuscate_email("j@x.io")
    end

    should "handle single character local part" do
      assert_equal "a@e******.com", obfuscate_email("a@example.com")
    end

    should "handle subdomain in TLD" do
      assert_equal "u***@m***.co.uk", obfuscate_email("user@mail.co.uk")
    end

    should "return nil for nil input" do
      assert_nil obfuscate_email(nil)
    end

    should "return empty string for empty input" do
      assert_equal "", obfuscate_email("")
    end

    should "return original for invalid email without @" do
      assert_equal "notanemail", obfuscate_email("notanemail")
    end

    should "return original for invalid email without domain" do
      assert_equal "user@", obfuscate_email("user@")
    end
  end
end
