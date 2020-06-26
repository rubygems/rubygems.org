module Castle
  class LogoutSucceeded < TrackEvent
    def perform
      track(::Castle::Events::LOGOUT_SUCCEEDED)
    end
  end
end
