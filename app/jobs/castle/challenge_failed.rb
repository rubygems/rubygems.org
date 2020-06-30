module Castle
  class ChallengeFailed < TrackEvent
    def perform
      track(::Castle::Events::CHALLENGE_FAILED)
    end
  end
end
