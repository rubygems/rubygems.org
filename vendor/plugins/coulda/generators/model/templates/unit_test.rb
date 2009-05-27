require File.dirname(__FILE__) + '/../test_helper'

class <%= class_name %>Test < ActiveSupport::TestCase
  should "be valid with factory" do
    assert_valid Factory.build(:<%= file_name -%>)
  end
<% attributes.each do |attribute| -%>
<% if attribute.reference? -%>
  should_belong_to :<%= attribute.name %>
  should_have_index :<%= attribute.name %>_id
<% end -%>
<% if attribute.type == :paperclip -%>
  should_have_attached_file :<%= attribute.name %>
<% end -%>
<% end -%> 
end
