# frozen_string_literal: true

require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get accounts_index_url
    assert_response :success
  end

  test 'should get show' do
    get accounts_show_url
    assert_response :success
  end

  test 'should get edit' do
    get accounts_edit_url
    assert_response :success
  end
end
