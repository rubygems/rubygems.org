# :yamlish converts object to JSON and back before converting to YAML in order to
# strip the object type (e.g. !ruby/ActiveRecord:Rubygem) from response
# TODO: Remove :yamlish once we know how to strip object type with to_yaml
ActionController::Renderers.add :yaml do |obj, options|
  data = options[:yamlish] ? MultiJson.decode(obj.to_json).to_yaml : obj.to_yaml
  send_data data, :type => 'text/yaml'
end
