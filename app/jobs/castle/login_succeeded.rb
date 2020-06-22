module Castle
  class LoginSucceeded < TrackEvent
    def perform
      castle_client
        .track(
          event: '$login.succeeded',
          user_id: user_id,
          user_traits: user_traits
        ).freeze
    end
  end
end
