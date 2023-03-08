class LinksetResource < Avo::BaseResource
  self.title = :id
  self.includes = [:rubygem]
  self.visible_on_sidebar = false

  field :id, as: :id, link_to_resource: true
  field :rubygem, as: :belongs_to

  Linkset::LINKS.each do |link|
    field link, as: :text, format_using: ->(value) { link_to value, value if value.present? }
  end
end
