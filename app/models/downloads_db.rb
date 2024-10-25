class DownloadsDB < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :downloads }

  extend Timescaledb::ActsAsHypertable
  include Timescaledb::ContinuousAggregatesHelper
end
