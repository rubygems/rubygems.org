class LogDownloadResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end
  class BackendFilter < ScopeBooleanFilter; end
  filter BackendFilter, arguments: {default: LogDownload.backends.transform_values { true } }
  class StatusFilter < ScopeBooleanFilter; end
  filter StatusFilter, arguments: {default: LogDownload.statuses.transform_values { true } }
  field :id, as: :id
  # Fields generated from the model
  field :key, as: :text
  field :directory, as: :text
  field :backend, as: :select, enum: LogDownload.backends
  field :status, as: :select, enum: LogDownload.statuses
  # add fields here
end
