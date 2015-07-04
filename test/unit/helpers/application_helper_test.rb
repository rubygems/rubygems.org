require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  should 'sanitize descriptions' do
    text = '<script>alert("foo");</script>Rails authentication & authorization'
    rubygem = create(:rubygem, name: "SomeGem")
    create(:version, rubygem: rubygem, number: "3.0.0", platform: "ruby", description: text)

    assert_equal 'Rails authentication &amp; authorization', short_info(rubygem.versions.most_recent)
    assert short_info(rubygem.versions.most_recent).html_safe?
  end
end
