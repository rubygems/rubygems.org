class DownloadResource < Avo::BaseResource
  self.title = :query
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  self.find_record_method = lambda { |model_class:, id:, params:| # rubocop:disable Lint/UnusedBlockArgument
    # In case of perfoming action `id` becomes an array of `ids`
    split = lambda { |s|
      parts = s.split("_")
      raise ArgumentError unless parts.size == 4
      { rubygem_id: parts[0], version_id: parts[1], log_ticket_id: parts[2].presence, occurred_at: parts[3] }
    }

    if id.is_a?(Array)
      id.reduce(model_class) { |a, e| a.or.where(split[e]) }
    else
      model_class.find_by!(split[id])
    end
  }

  # Fields generated from the model
  field :occurred_at, as: :date_time
  field :rubygem, as: :belongs_to
  field :version, as: :belongs_to
  field :log_ticket, as: :belongs_to
  field :downloads, as: :number
  # add fields here
end
