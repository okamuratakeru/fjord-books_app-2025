class AccountsController < ApplicationController
  def index
    @users = User.page(params[:page]).per(20)
  end

  def show
  end

  def edit
  end
end
