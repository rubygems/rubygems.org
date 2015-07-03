class Api::DeprecatedController < ApplicationController
  def index
    render status: :forbidden, text: %{
      This version of the Gemcutter plugin has been deprecated.
      Please install the latest version using: gem update gemcutter
    }
  end
end
