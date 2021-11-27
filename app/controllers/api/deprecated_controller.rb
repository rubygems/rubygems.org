class Api::DeprecatedController < Api::BaseController
  def index
    render status: :forbidden, plain: "This version of the Gemcutter plugin has been deprecated." \
                                      "Please install the latest version using: gem update gemcutter"
  end
end
