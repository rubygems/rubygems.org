ActionController::Renderers.add :yaml do |obj, _|
  # Create a serializable resource instance
  serializable_resource = ActiveModelSerializers::SerializableResource.new(obj)

  data = JSON.parse(serializable_resource.to_json).to_yaml
  send_data data, type: 'text/yaml'
end
