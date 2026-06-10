# frozen_string_literal: true

class ReportLink < ApplicationRecord
  belongs_to :source_report, class_name: 'Report', inverse_of: :source_report_links
  belongs_to :target_report, class_name: 'Report', inverse_of: :target_report_links

  validates :source_report_id, uniqueness: { scope: :target_report_id }
end
