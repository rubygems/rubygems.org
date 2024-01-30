module Events::Recordable
  extend ActiveSupport::Concern

  included do
    has_many :events, class_name: "Events::#{name}Event", dependent: :destroy, inverse_of: model_name.param_key
  end
end
