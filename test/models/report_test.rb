# frozen_string_literal: true

require 'test_helper'

class ReportTest < ActiveSupport::TestCase
  describe '#save_mentions' do
    let(:mentioned) { reports(:one) }
    let(:new_mentioned) { reports(:two) }

    def create_report(user:, content:)
      Report.create!(user:, title: 'テスト日報', content:)
    end

    it '本文に他の日報へのリンクがあるとメンションに追加される' do
      mentioning = create_report(user: users(:two), content: "http://localhost:3000/reports/#{mentioned.id}")
      assert_includes mentioning.mentioning_reports, mentioned
    end

    it '本文を更新すると古いメンションは残らない' do
      report = create_report(user: users(:one), content: 'placeholder')
      report.update!(content: "http://localhost:3000/reports/#{report.id}")
      assert_empty report.mentioning_reports
    end

    it '再保存時に古いメンション関係をリセットして新しい状態を保存する' do
      mentioning = create_report(user: users(:one), content: "http://localhost:3000/reports/#{mentioned.id}")
      mentioning.update!(content: "http://localhost:3000/reports/#{new_mentioned.id}")
      mentioning.reload
      assert_includes mentioning.mentioning_reports, new_mentioned
      assert_not_includes mentioning.mentioning_reports, mentioned
    end

    it '同じリンクが複数あってもメンションは1つだけになる' do
      url = "http://localhost:3000/reports/#{mentioned.id}"
      mentioning = create_report(user: users(:two), content: "#{url} #{url}")
      assert_equal 1, mentioning.mentioning_reports.count
    end
  end

  describe '#editable?' do
    let(:report) { reports(:one) }

    it '日報作成者の場合trueを返す' do
      assert report.editable?(report.user)
    end

    it '日報作成者ではない場合falseを返す' do
      assert_not report.editable?(users(:two))
    end
  end
end
