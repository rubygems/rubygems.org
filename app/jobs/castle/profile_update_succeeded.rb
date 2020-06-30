module Castle
  class ProfileUpdateSucceeded < TrackEvent
    def perform
      track(::Castle::Events::PROFILE_UPDATE_SUCCEEDED)
    end
  end
end
