# frozen_string_literal: true

require "test_helper"

class MarkdownTest < ActiveSupport::TestCase
  test "renders markdown as html" do
    html = Gemcutter::Markdown.render("# Publishing Gems\n\nUse `gem push`.")

    assert_includes html, "<h1 id=\"publishing-gems\">Publishing Gems</h1>"
    assert_includes html, "<code>gem push</code>"
    assert_predicate html, :html_safe?
  end

  test "allows markdown tables" do
    html = Gemcutter::Markdown.render(<<~MARKDOWN)
      | Name | Value |
      | ---- | ----- |
      | MFA  | true  |
    MARKDOWN

    assert_includes html, "<table>"
    assert_includes html, "<td>MFA</td>"
  end

  test "removes unsafe html from markdown" do
    html = Gemcutter::Markdown.render(<<~MARKDOWN)
      # Safe

      <script>alert("pwnd")</script>
      <a href="javascript:alert(1)" onclick="alert(2)">bad link</a>
    MARKDOWN

    refute_includes html, "<script"
    refute_includes html, "javascript:"
    refute_includes html, "onclick"
    assert_includes html, ">bad link</a>"
  end
end
