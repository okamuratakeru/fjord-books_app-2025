# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  describe '#name_or_email' do
    it '名前があれば名前を返す' do
      user = User.new(name: 'テストユーザー', email: 'with_name@example.com', password: 'password')
      assert_equal 'テストユーザー', user.name_or_email
    end

    it '名前がなければメールアドレスを返す' do
      user = User.new(email: 'without_name@example.com', password: 'password')
      assert_equal 'without_name@example.com', user.name_or_email
    end
  end
end
