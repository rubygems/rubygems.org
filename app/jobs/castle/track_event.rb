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

    def castle_client
      ::Castle::Client.new(@context)
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
      @user ? @user.id : false
    end
  end
end
