# frozen_string_literal: true

class Avo::Resources::Sponsor < Avo::BaseResource
  self.title = :name
  self.includes = [logo_attachment: :blob]
  self.default_sort_column = :position
  self.default_sort_direction = :asc
  self.index_query = -> { query.ordered }

  def actions
    action Avo::Actions::SetSponsorFooterVisibility
    action Avo::Actions::SetSponsorCategory
  end

  def fields
    field :id, as: :id, hide_on: :index
    field :name, as: :text, link_to_resource: true
    field :website_url, as: :text
    field :tier, as: :select, name: "Category", enum: ::Sponsor.tiers
    field :anonymous, as: :boolean
    field :show_in_footer, as: :boolean, help: "Independent of category. Anonymous sponsors are always hidden, even when checked."
    field :position, as: :number, sortable: true,
      help: "Lower numbers appear first. Edit positions to reorder sponsors; gaps and ties are allowed, with ties ordered by ID."
    field :logo, as: :file, direct_upload: false,
      accept: "image/png,image/webp",
      help: "Upload an optimized transparent PNG or WebP, no larger than 256 KB. " \
            "The footer uses its alpha channel as a monochrome mask in light/dark mode. SVG is not accepted."
    field :created_at, as: :date_time, readonly: true, only_on: %i[index show]
    field :updated_at, as: :date_time, readonly: true, only_on: %i[index show]
  end
end
