module Castle
  class ProfileUpdateFailed < TrackEvent
    def perform
      track(::Castle::Events::PROFILE_UPDATE_FAILED)
    end
  end
end
