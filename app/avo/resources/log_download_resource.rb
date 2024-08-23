class LogDownloadResource < Avo::BaseResource
  self.title = :id
  self.includes = []

  class BackendFilter < ScopeBooleanFilter; end
  filter BackendFilter, arguments: {default: LogDownload.backends.transform_values { true } }
  class StatusFilter < ScopeBooleanFilter; end
  filter StatusFilter, arguments: {default: LogDownload.statuses.transform_values { true } }

  field :id, as: :id
  field :key, as: :text
  field :directory, as: :text
  field :backend, as: :select, enum: LogDownload.backends
  field :status, as: :select, enum: LogDownload.statuses
end
