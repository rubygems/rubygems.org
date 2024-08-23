class DownloadsDB < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :downloads }
end
