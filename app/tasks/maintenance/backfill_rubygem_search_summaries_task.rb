# frozen_string_literal: true

# Creates the RubygemSearchSummary row for gems pushed before the table existed.
# ReindexRubygemJob keeps rows current afterwards. Safe to rerun: process reads the
# gem's current most recent version, so it never writes an older summary than the app.
class Maintenance::BackfillRubygemSearchSummariesTask < MaintenanceTasks::Task
  def collection
    Rubygem.where.missing(:search_summary)
  end

  def process(rubygem)
    RubygemSearchSummary.refresh!(rubygem)
  end
end
