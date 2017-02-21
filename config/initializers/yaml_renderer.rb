ActionController::Renderers.add :yaml do |obj, _|
  # Create a serializable resource instance
  serializable_resource = ActiveModelSerializers::SerializableResource.new(obj)

  data = serializable_resource.as_json.to_yaml
  send_data data, type: 'text/yaml'
end
