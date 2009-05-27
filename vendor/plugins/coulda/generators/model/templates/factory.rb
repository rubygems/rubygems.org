Factory.define :<%= file_name %> do |<%= file_name %>|
<% attributes.each do |attribute| -%>
  <%= factory_line(attribute, file_name) %>
<% end -%>
end
