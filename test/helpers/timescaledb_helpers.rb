module TimescaledbHelpers
  extend ActiveSupport::Concern

  included do
    def refresh_all_caggs!
      Download::MaterializedViews.each do |cagg|
        cagg.refresh!
      end
    end
  end
end
