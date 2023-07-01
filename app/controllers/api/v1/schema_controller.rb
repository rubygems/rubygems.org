class Api::V1::SchemaController < Api::BaseController
  def show
    schema = YAML.load Rails.root.join("app", "controllers", "api", "v1", "api.yaml").read
    respond_to do |format|
      format.json { render json: schema }
      format.yaml { render yaml: schema }
    end
  end
end
