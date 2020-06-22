module Castle
  class LoginFailed < TrackEvent
    def perform
      castle_client
        .track(
          event: '$login.failed',
          user_id: user_id,
          user_traits: user_traits
        ).freeze
    end
  end
end
