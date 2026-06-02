# 日報メンション機能 設計書

## 概要

日報の本文に別の日報のURLを記載すると、言及された側の日報に言及元の日報がリンク表示される機能。

---

## 機能要件

### 作成

AさんがBさんの日報URLを自分の日報本文に記述して保存すると、Bさんの日報詳細画面にAさんの日報へのリンクが表示される。

### 更新

| 操作 | 結果 |
|------|------|
| 言及先をBさん→Cさんに変更 | Bさんの日報からリンクが消え、Cさんの日報にリンクが追加される |
| 言及元（Aさん）の日報タイトルを変更 | Bさんの日報に表示されているリンクのタイトルも追従して更新される |

### 削除

AさんがBさんの日報URLを本文から削除して保存すると、Bさんの日報からリンクが消える。  
Aさんの日報自体が削除された場合も同様に、言及先日報からリンクが消える。

---

## 処理の流れ

```
日報の保存（create / update）
  ↓
本文から http://localhost:3000/reports/:report_id 形式のURLを正規表現で抽出
  ↓
URLが0件 → 既存の report_links（source_report_id が自分）を全削除してスルー
  ↓
URLから report_id を取得し、該当 Report を特定
  ↓
【差分計算】
  現在の target_report_ids（DB） vs 新しい target_report_ids（本文から抽出）
  ↓
  追加分 → report_links を INSERT
  削除分 → report_links を DELETE
  変化なし → スルー
```

---

## データベース設計

### テーブル: `report_links`

| カラム名 | 型 | 制約 | 説明 |
|---|---|---|---|
| `id` | integer | PK | |
| `source_report_id` | integer | NOT NULL, FK → reports | 言及する側の日報ID |
| `target_report_id` | integer | NOT NULL, FK → reports | 言及される側の日報ID |
| `created_at` | datetime | NOT NULL | |
| `updated_at` | datetime | NOT NULL | |

### インデックス

| インデックス | 目的 |
|---|---|
| `(source_report_id)` | ある日報が言及している先を高速に取得 |
| `(target_report_id)` | ある日報に言及している元を高速に取得（詳細画面表示） |
| `(source_report_id, target_report_id)` UNIQUE | 同じ組み合わせの重複登録を防止 |

### 設計の根拠

- Report と Report は多対多の関係（1つの日報が複数の日報を言及でき、1つの日報が複数の日報から言及される）のため中間テーブルで表現する
- `source_report_id` だけでは言及の方向が表現できないため `target_report_id` が必要
- User は Report に `belongs_to :user` があるため、report_links に `user_id` は不要

---

## モデル設計

### `ReportLink` モデル（新規）

```ruby
class ReportLink < ApplicationRecord
  belongs_to :source_report, class_name: 'Report'
  belongs_to :target_report, class_name: 'Report'

  validates :source_report_id, uniqueness: { scope: :target_report_id }
end
```

### `Report` モデルへの追加

```ruby
class Report < ApplicationRecord
  has_many :report_links_as_source, class_name: 'ReportLink',
                                    foreign_key: :source_report_id,
                                    dependent: :destroy
  has_many :report_links_as_target, class_name: 'ReportLink',
                                    foreign_key: :target_report_id,
                                    dependent: :destroy

*関係値を書かないとどうなるんだろう?
  # 自分が言及している日報
  has_many :mentioned_reports, through: :report_links_as_source,
                               source: :target_report

  # 自分を言及している日報
  has_many :mentioning_reports, through: :report_links_as_target,
                                source: :source_report

  after_save :sync_report_links

  private

  REPORT_URL_PATTERN = %r{http://localhost:3000/reports/(\d+)}

  def sync_report_links
    new_target_ids = content.scan(REPORT_URL_PATTERN).flatten.map(&:to_i).uniq
    new_target_ids.delete(id) # 自己言及は除外

    current_target_ids = report_links_as_source.pluck(:target_report_id)

    ids_to_add    = new_target_ids - current_target_ids
    ids_to_remove = current_target_ids - new_target_ids

    report_links_as_source.where(target_report_id: ids_to_remove).destroy_all
    ids_to_add.each do |target_id|
      report_links_as_source.find_or_create_by!(target_report_id: target_id)
    rescue ActiveRecord::RecordNotFound
      # 存在しない report_id はスキップ
    end
  end
end
```

---

## コントローラー設計

`ReportsController` への変更は最小限。  
言及の同期は `Report` モデルの `after_save` コールバックで完結するため、コントローラーの変更は不要。
---

## ビュー設計

### 日報詳細画面 (`reports/show.html.erb`) への追加

```erb
<%# 自分を言及している日報一覧 %>
<% if @report.mentioning_reports.any? %>
  <section>
    <h2>この日報を言及している日報</h2>
    <ul>
      <% @report.mentioning_reports.includes(:user).each do |report| %>
        <li>
          <%= link_to report.title, report %>
          （<%= report.user.name %>）
        </li>
      <% end %>
    </ul>
  </section>
<% end %>
```

### コントローラーでの事前ロード

```ruby
def show
  @report = Report.find(params[:id])
  @mentioning_reports = @report.mentioning_reports.includes(:user)
end
```

---

## マイグレーション

```ruby
class CreateReportLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :report_links do |t|
      t.references :source_report, null: false, foreign_key: { to_table: :reports }
      t.references :target_report, null: false, foreign_key: { to_table: :reports }
      t.timestamps
    end

    add_index :report_links, %i[source_report_id target_report_id], unique: true
  end
end
```

---

## 考慮事項

| 項目 | 対応方針 |
|---|---|
| 自己言及（自分の日報URLを自分の日報に貼る） | `sync_report_links` 内で `id` を除外 |
| 存在しない report_id への言及 | `find_or_create_by!` の例外を rescue してスキップ |
| URL 形式の変更（本番環境など） | `REPORT_URL_PATTERN` を定数化して変更を局所化 |
| タイトル更新時のリンク反映 | DB の report_links は ID を持つだけなので、表示時に最新タイトルを取得できる（追加対応不要） |
