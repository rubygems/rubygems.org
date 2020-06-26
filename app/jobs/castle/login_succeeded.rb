module Castle
  class LoginSucceeded < TrackEvent
    def perform
      track(::Castle::Events::LOGIN_SUCCEEDED)
    end
  end
end
