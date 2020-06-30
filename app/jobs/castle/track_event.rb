module Castle
  class TrackEvent
    ALLOWED_TRAITS = %w[
      email
      created_at
      updated_at
    ]
    def initialize(user, context)
      @user = user
      @context = context
    end

    def track(event_name)
      ::Castle::Client
        .new(@context)
        .track(track_params(event_name))
    end

    private

    def track_params(event_name)
      {
        event: event_name,
        user_id: user_id,
        user_traits: user_traits
      }
    end

    def user_traits
      return {} if @user.nil?
      ALLOWED_TRAITS.each_with_object({}) do |trait, traits|
        if trait == 'created_at'
          traits['registered_at'] = @user.attributes[trait]
        else
          traits[trait] = @user.attributes[trait]
        end
      end
    end

    def user_id
      @user&.id ? @user.id : false
    end
  end
end
