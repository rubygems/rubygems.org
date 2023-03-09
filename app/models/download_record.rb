class DownloadRecord < ApplicationRecord
  include Timescaledb::Rails::Model

  self.abstract_class = true

  connects_to database: { writing: :downloads, reading: :downloads }
end
