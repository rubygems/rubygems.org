module TimescaledbHelpers
  extend ActiveSupport::Concern

  included do
    def refresh_all_caggs!
      Download.connection.commit_db_transaction
      Download::MaterializedViews.each do |cagg|
        cagg.refresh!
      end
    end
  end
end
