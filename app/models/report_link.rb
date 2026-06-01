# frozen_string_literal: true

class ReportLink < ApplicationRecord
  belongs_to :source_report, class_name: 'Report'
  belongs_to :target_report, class_name: 'Report'

  validates :source_report_id, uniqueness: { scope: :target_report_id }
end
