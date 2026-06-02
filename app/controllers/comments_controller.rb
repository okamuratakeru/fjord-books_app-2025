# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_commentable
  before_action :set_comment, only: :destroy
  before_action :require_owner, only: :destroy

  def create
    @comment = @commentable.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to @commentable, notice: t('controllers.common.notice_create', name: Comment.model_name.human)
    else
      redirect_to @commentable, alert: 'コメントを投稿できませんでした。'
    end
  end

  def destroy
    @comment.destroy!
    redirect_to @commentable, status: :see_other,
                              notice: t('controllers.common.notice_destroy', name: Comment.model_name.human)
  end

  private

  def set_commentable
    if params[:book_id]
      @commentable = Book.find(params[:book_id])
    elsif params[:report_id]
      @commentable = Report.find(params[:report_id])
    end
  end

  def set_comment
    @comment = @commentable.comments.find(params.expect(:id))
  end

  def comment_params
    params.expect(comment: [:content])
  end

  def require_owner
    redirect_to @commentable, status: :see_other if @comment.user != current_user
  end
end
