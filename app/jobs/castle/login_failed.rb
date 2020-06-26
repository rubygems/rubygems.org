module Castle
  class LoginFailed < TrackEvent
    def perform
      track(::Castle::Events::LOGIN_FAILED)
    end
  end
end
