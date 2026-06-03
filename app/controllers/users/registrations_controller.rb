# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super do |resource|
      if resource.persisted?
        sign_out resource
        flash[:notice] = t('devise.registrations.signed_up')
        redirect_to new_user_session_path and return
      else
        flash.now[:alert] = t('devise.registrations.sign_up_failed')
      end
    end
  end

  protected

  def after_update_path_for(resource)
    user_path(resource)
  end
end
