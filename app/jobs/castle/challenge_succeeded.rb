module Castle
  class ChallengeSucceeded < TrackEvent
    def perform
      track(::Castle::Events::CHALLENGE_SUCCEEDED)
    end
  end
end
