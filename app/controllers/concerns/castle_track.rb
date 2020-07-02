module CastleTrack
  extend ActiveSupport::Concern

  included do
    def track_castle_event(castle_event, user)
      context = ::Castle::Client.to_context(request)
      Delayed::Job.enqueue(castle_event.new(user, context), priority: PRIORITIES[:stats])
    end
  end
end
