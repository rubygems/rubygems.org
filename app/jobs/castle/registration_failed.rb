module Castle
  class RegistrationFailed < TrackEvent
    def perform
      track(::Castle::Events::REGISTRATION_FAILED)
    end
  end
end
