class Avo::Resources::GemDownload < Avo::BaseResource
  self.title = :inspect
  self.includes = %i[rubygem version]

  self.index_query = lambda {
    query.order(count: :desc)
  }

  class SpecificityFilter < Avo::Filters::ScopeBooleanFilter; end

  def filters
    filter SpecificityFilter, arguments: { default: { for_versions: true, for_rubygems: true, total: true } }
  end

  def fields
    field :title, as: :text, link_to_resource: true do |_model, _resource, _view|
      if record.version
        "#{record.version.full_name} (#{record.count.to_fs(:delimited)})"
      elsif record.rubygem
        "#{record.rubygem} (#{record.count.to_fs(:delimited)})"
      else
        "All Gems (#{record.count.to_fs(:delimited)})"
      end
    end

    field :rubygem, as: :belongs_to
    field :version, as: :belongs_to
    field :count, as: :number, sortable: true, index_text_align: :right, format_using: -> { value.to_fs(:delimited) }, default: 0

    field :id, as: :id, hide_on: :index
  end
end
