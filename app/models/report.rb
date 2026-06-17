# frozen_string_literal: true

class Report < ApplicationRecord
  belongs_to :user
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :source_report_links, class_name: 'ReportLink',
                                 foreign_key: :source_report_id,
                                 dependent: :destroy,
                                 inverse_of: :source_report
  has_many :target_report_links, class_name: 'ReportLink',
                                 foreign_key: :target_report_id,
                                 dependent: :destroy,
                                 inverse_of: :target_report
  has_many :mentioned_reports,  through: :source_report_links, source: :target_report
  has_many :mentioning_reports, through: :target_report_links, source: :source_report

  scope :latest, -> { order(id: :desc) }

  validates :title, presence: true
  validates :content, presence: true

  after_save :sync_report_links

  def editable?(target_user)
    user == target_user
  end

  def created_on
    created_at.to_date
  end

  private

  REPORT_URL_PATTERN = %r{http://localhost:3000/reports/(\d+)}

  def sync_report_links
    new_target_ids = content.scan(REPORT_URL_PATTERN).flatten
    self.mentioned_reports = Report.where(id: new_target_ids).where.not(id: id)
  end
end
