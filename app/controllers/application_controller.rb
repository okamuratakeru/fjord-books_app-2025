# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :configure_account_update_params, if: :devise_controller?

  def after_sign_in_path_for(_resource)
    accounts_path
  end

  protected

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: %i[postal_code address bio])
  end
end
