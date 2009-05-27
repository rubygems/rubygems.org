class <%= class_name %> < ActiveRecord::Base
<% attributes.select(&:reference?).each do |each| -%>
  belongs_to :<%= each.name %>
<% end -%>
<% attributes.select { |each| each.type == :paperclip }.each do |each| -%>
  has_attached_file :<%= each.name %>
<% end -%>
end
