# frozen_string_literal: true

class Avo::Resources::Advisory < Avo::BaseResource
  self.model_class = ::Advisory
  self.title = :identifier
  self.includes = []
  self.search = {
    query: lambda {
      search_term = ActiveRecord::Base.sanitize_sql_like(params[:q])
      query.where("identifier LIKE :q OR rubygem_name LIKE :q", q: "#{search_term}%")
    }
  }

  def fields
    field :id, as: :id, hide_on: :index
    field :identifier, as: :text, link_to_resource: true
    field :type, as: :text
    field :rubygem_name, as: :text
    field :rubygem, as: :belongs_to
    field :aliases, as: :tags
    field :summary, as: :textarea
    field :severity, as: :text
    field :url, as: :text
    field :published_at, as: :date_time, sortable: true
    field :modified_at, as: :date_time, sortable: true
    field :withdrawn_at, as: :date_time, sortable: true
    field :ranges, as: :json_viewer, only_on: :show
    field :payload, as: :json_viewer, only_on: :show
  end
end
