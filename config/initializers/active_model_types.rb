ActiveSupport.on_load(:active_model) do
  ActiveModel::Type.register(:global_id, Types::GlobalId)
  ActiveModel::Type.register(:duration, Types::Duration)
  ActiveModel::Type.register(:role, Types::Role)
end
