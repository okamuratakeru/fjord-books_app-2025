# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super do |resource|
      if resource.persisted?
        sign_out resource
        redirect_to new_user_session_path and return
      end
    end
  end

  protected

  def after_update_path_for(resource)
    account_path(resource)
  end
end
