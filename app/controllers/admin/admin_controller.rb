class Admin::AdminController < ApplicationController
  include GitHubOAuthable

  def index
  end

  def logout
    admin_logout
  end
end
