# app/controllers/concerns/recorder.rb

module Recorder
  extend ActiveSupport::Concern

  private

  def record_transparency_log_event(event_type, record)
    attributes =
      case record
      when Pusher, Deletion
        gem_version_attributes(event_type, record)
      when User
        ownership_change_attributes(event_type, record)
      else
        return
      end

    TransparencyLog::Recorder.new.record(attributes)
  rescue StandardError => e
    Rails.error.report(e, handled: true)
  end

  def gem_version_attributes(event_type, record)
    version = record.version
    rubygem = record.is_a?(Pusher) ? record.rubygem : version.rubygem

    {
      event_type: event_type,
      resource_type: "rubygem",
      resource_name: rubygem.name,
      resource_id: rubygem.id.to_s,
      subject_type: "gem_version",
      subject_name: version.full_name,
      subject_id: version.id.to_s,
      actor_type: @api_key.user? ? "user" : "unknown",
      actor_id: @api_key.owner_id.to_s,
      actor_handle: @api_key.owner&.name,
      authentication_method: "api_key"
    }
  end

  def ownership_change_attributes(event_type, owner)
    {
      event_type: event_type,
      resource_type: "rubygem",
      resource_name: @rubygem.name,
      resource_id: @rubygem.id.to_s,
      subject_type: "user",
      subject_name: owner.handle,
      subject_id: owner.id.to_s,
      actor_type: "user",
      actor_id: @api_key.user.id.to_s,
      actor_handle: @api_key.user.handle,
      authentication_method: "api_key"
    }
  end
end
