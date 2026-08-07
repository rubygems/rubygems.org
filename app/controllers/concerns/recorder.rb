# app/controllers/concerns/recorder.rb

module Recorder
  extend ActiveSupport::Concern

  private

  def record_transparency_log_event(record)
    attributes =
      case record
      when Pusher
        gem_push_attributes(record)
      when User
        ownership_change_attributes(record)
      else
        return
      end

    TransparencyLog::Recorder.new.record(attributes)
  rescue StandardError => e
    Rails.error.report(e, handled: true)
  end

  def gem_push_attributes(gemcutter)
    rubygem = gemcutter.rubygem
    version = gemcutter.version

    {
      event_type: "gem_push",
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

  def ownership_change_attributes(owner)
    {
      event_type: "ownership_change",
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
