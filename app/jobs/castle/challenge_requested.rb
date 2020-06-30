module Castle
  class ChallengeRequested < TrackEvent
    def perform
      track(::Castle::Events::CHALLENGE_REQUESTED)
    end
  end
end
