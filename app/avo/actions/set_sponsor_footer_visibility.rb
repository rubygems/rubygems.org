# frozen_string_literal: true

class Avo::Actions::SetSponsorFooterVisibility < Avo::Actions::ApplicationAction
  self.name = "Set Sponsor Footer Visibility"
  self.message = "Show or hide the selected sponsors in the footer. Anonymous sponsors always remain hidden."
  self.authorize = -> { Admin::SponsorPolicy.new(current_user, Sponsor).act_on? }

  def fields
    field :show_in_footer, as: :boolean, name: "Show in footer"
    super
  end

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(record)
      record.update!(show_in_footer: ActiveModel::Type::Boolean.new.cast(fields[:show_in_footer]))
    end
  end
end
