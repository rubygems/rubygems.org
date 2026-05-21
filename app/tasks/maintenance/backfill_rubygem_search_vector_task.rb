# frozen_string_literal: true

# Populates rubygems.search_vector for the PostgreSQL full-text search backend
# (DatabaseSearcher). Run once after deploying AddSearchVectorToRubygems; afterwards
# the column is kept current by ReindexRubygemJob via Rubygem#update_search_vector.
class Maintenance::BackfillRubygemSearchVectorTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  def collection
    Rubygem.with_versions
  end

  def process(rubygem)
    rubygem.update_search_vector
  end
end
