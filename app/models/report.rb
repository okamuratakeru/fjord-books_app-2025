# frozen_string_literal: true

class Report < ApplicationRecord
  belongs_to :user
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :report_links_as_source, class_name: 'ReportLink',
                                    foreign_key: :source_report_id,
                                    dependent: :destroy,
                                    inverse_of: :source_report
  has_many :report_links_as_target, class_name: 'ReportLink',
                                    foreign_key: :target_report_id,
                                    dependent: :destroy,
                                    inverse_of: :target_report
  has_many :mentioned_reports,  through: :report_links_as_source, source: :target_report
  has_many :mentioning_reports, through: :report_links_as_target, source: :source_report

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
    new_target_ids = content.scan(REPORT_URL_PATTERN).flatten.map(&:to_i).uniq
    new_target_ids.delete(id)

    current_target_ids = report_links_as_source.pluck(:target_report_id)

    ids_to_add    = new_target_ids - current_target_ids
    ids_to_remove = current_target_ids - new_target_ids

    report_links_as_source.where(target_report_id: ids_to_remove).destroy_all
    ids_to_add.each do |target_id|
      report_links_as_source.find_or_create_by!(target_report_id: target_id)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
