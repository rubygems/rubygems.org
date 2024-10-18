module Onboarding
  class UsersController < BaseController
    def edit
    end

    def update
      redirect_to edit_onboarding_confirm_path
    end
  end
end