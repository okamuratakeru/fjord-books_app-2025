# frozen_string_literal: true

require 'application_system_test_case'

class ReportsTest < ApplicationSystemTestCase
  include Warden::Test::Helpers

  setup do
    @user = users(:alice)
    @report = reports(:alice_report)
    login_as @user, scope: :user
  end

  teardown do
    Warden.test_reset!
  end

  test '日報を作成できる' do
    visit new_report_path
    fill_in 'タイトル', with: '新しい日報'
    fill_in '内容',     with: '日報の内容'
    assert_difference 'Report.count', 1 do
      click_on '登録する'
      assert_text '日報が作成されました。'
    end
    assert_current_path report_path(Report.last)
  end

  test 'タイトルと内容が空だと日報を作成できない' do
    visit new_report_path
    assert_no_difference 'Report.count' do
      click_on '登録する'
      assert_text 'この日報は保存できませんでした'
    end
  end

  test '日報一覧に日報が表示される' do
    visit reports_path
    assert_text @report.title
  end

  test '日報の詳細が表示される' do
    visit report_path(@report)
    assert_text @report.title
    assert_text @report.content
  end

  test '日報を編集できる' do
    visit edit_report_path(@report)
    fill_in 'タイトル', with: '更新した日報'
    fill_in '内容', with: '更新した内容'
    click_on '更新する'
    assert_text '日報が更新されました。'
    assert_current_path report_path(@report)
  end

  test 'タイトルと内容が空だと日報を更新できない' do
    visit edit_report_path(@report)
    fill_in 'タイトル', with: ''
    fill_in '内容', with: ''
    assert_no_difference 'Report.count' do
      click_on '更新する'
    end
  end

  test '日報を削除すると一覧から消える' do
    report = reports(:report_to_delete)
    assert_difference 'Report.count', -1 do
      visit report_path(report)
      click_on 'この日報を削除'
      assert_text '日報が削除されました。'
    end
    assert_current_path reports_path
    assert_no_text '削除する日報'
  end
end
