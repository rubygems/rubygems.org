# frozen_string_literal: true

class ApplicationView < ApplicationComponent
  # The ApplicationView is an abstract class for all your views.

  # By default, it inherits from `ApplicationComponent`, but you
  # can change that to `Phlex::HTML` if you want to keep views and
  # components independent.

  def title=(title)
    @_view_context.instance_variable_set :@title, title
  end
end
