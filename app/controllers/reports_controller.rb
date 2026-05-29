# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :set_report, only: %i[show edit update destroy]
  before_action :require_owner, only: %i[edit update destroy]

  def index
    @reports = Report.includes(:user).order(created_at: :desc).page(params[:page])
  end

  def show; end

  def new
    @report = Report.new
  end

  def edit; end

  def create
    @report = current_user.reports.build(report_params)

    if @report.save
      redirect_to @report, notice: t('controllers.common.notice_create', name: Report.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @report.update(report_params)
      redirect_to @report, notice: t('controllers.common.notice_update', name: Report.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @report.destroy!
    redirect_to reports_path, status: :see_other,
                              notice: t('controllers.common.notice_destroy', name: Report.model_name.human)
  end

  private

  def set_report
    @report = Report.find(params.expect(:id))
  end

  def report_params
    params.expect(report: %i[title content])
  end

  def require_owner
    redirect_to @report, status: :see_other if @report.user != current_user
  end
end
