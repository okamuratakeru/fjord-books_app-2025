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

    current_target_ids = source_report_links.pluck(:target_report_id)

    ids_to_add    = new_target_ids - current_target_ids
    ids_to_remove = current_target_ids - new_target_ids

    source_report_links.where(target_report_id: ids_to_remove).destroy_all
    ids_to_add.each do |target_id|
      source_report_links.find_or_create_by!(target_report_id: target_id)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
