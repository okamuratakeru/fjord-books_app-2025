# frozen_string_literal: true

require 'application_system_test_case'

class BooksTest < ApplicationSystemTestCase
  include Warden::Test::Helpers

  setup do
    @user = users(:alice)
    @book = books(:testbook)
    login_as @user, scope: :user
  end

  teardown do
    Warden.test_reset!
  end

  test '本を作成できる' do
    visit new_book_path
    fill_in 'タイトル', with: '新しい本'
    fill_in 'メモ',     with: '本のメモ'
    assert_difference 'Book.count', 1 do
      click_on '登録する'
      assert_text '本が作成されました。'
    end
    assert_current_path book_path(Book.last)
  end

  test '本の一覧が表示される' do
    visit books_path
    assert_text @book.title
  end

  test '本の詳細が表示される' do
    visit book_path(@book)
    assert_text @book.title
    assert_text @book.memo
  end

  test '本を編集できる' do
    visit edit_book_path(@book)
    fill_in 'タイトル', with: '更新した本'
    fill_in 'メモ', with: '更新したメモ'
    click_on '更新する'
    assert_text '本が更新されました。'
    assert_current_path book_path(@book)
  end

  test '本を削除すると一覧から消える' do
    book = Book.create!(title: '削除する本', memo: '削除するメモ')
    assert_difference 'Book.count', -1 do
      visit book_path(book)
      click_on 'この本を削除'
      assert_text '本が削除されました。'
    end
    assert_current_path books_path
    assert_no_text '削除する本'
  end
end
