class Api::BaseController < ApplicationController
  skip_before_action :require_ssl
end
