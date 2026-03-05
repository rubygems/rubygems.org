# frozen_string_literal: true

class Admin::AdminController < ApplicationController
  include GitHubOAuthable

  def logout
    admin_logout
  end
end
