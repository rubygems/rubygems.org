class Avo::Resources::Linkset < Avo::BaseResource
  self.includes = [:rubygem]
  self.visible_on_sidebar = false

  def fields
    field :id, as: :id, link_to_resource: true
    field :rubygem, as: :belongs_to

    Linkset::LINKS.each do |link|
      field link, as: :text, format_using: -> { link_to value, value if value.present? }
    end
  end
end
