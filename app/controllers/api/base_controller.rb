class Api::BaseController < ApplicationController
  skip_before_filter :require_ssl
end
