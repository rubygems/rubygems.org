class ApplicationRecord < ActiveRecord::Base
  include SemanticLogger::Loggable

  self.abstract_class = true
end
