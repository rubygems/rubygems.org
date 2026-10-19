# frozen_string_literal: true

class Avo::Actions::SetSponsorCategory < Avo::Actions::ApplicationAction
  self.name = "Set Sponsor Category"
  self.authorize = -> { Admin::SponsorPolicy.new(current_user, Sponsor).act_on? }

  def fields
    field :tier, as: :select, name: "Category", options: ::Sponsor.tiers.keys.index_by(&:humanize), required: true
    super
  end

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(record)
      record.update!(tier: fields[:tier])
    end
  end
end
