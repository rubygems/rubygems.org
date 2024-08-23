# This model is used to connect to the downloads database
class DownloadRecord < ApplicationRecord
  self.abstract_class = true
  extend Timescaledb::ActsAsHypertable
  connects_to database: { writing: :downloads, reading: :downloads }
end
