module Castle
  class RegistrationSucceeded < TrackEvent
    def perform
      track(::Castle::Events::REGISTRATION_SUCCEEDED)
    end
  end
end
