# frozen_string_literal: true

class Avo::Actions::RecordTemporaryPushGrantReview < Avo::Actions::TemporaryPushGrantAction
  self.name = "Record Technical Review"
  self.message = lambda {
    "Record that the change set and the exact gem files of grant ##{record.id} were independently reviewed?"
  }
  self.confirm_button_label = "Record review"

  def fields
    field :reviewer, as: :text, required: true,
      help: "Public account identifier of the technical reviewer: not the grantee, and not reviewing their own contributions."
    field :notes, as: :textarea, required: true,
      help: "Test suite result, reviewed range including release-mechanics changes, and how the built files were checked."
    super
  end

  class ActionHandler < Avo::Actions::TemporaryPushGrantAction::ActionHandler
    def handle_record(grant)
      return error("Reviewer and notes are required") if fields[:reviewer].blank? || fields[:notes].blank?

      grant.record_technical_review!(reviewer: fields[:reviewer], notes: fields[:notes])
      succeed "Recorded technical review of grant ##{grant.id} by #{fields[:reviewer]}"
    end
  end
end
