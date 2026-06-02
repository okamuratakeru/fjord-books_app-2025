# 日報メンション機能 実装手順

## 実装順序

1. マイグレーション作成・実行
2. `ReportLink` モデル作成
3. `Report` モデルに追記
4. `ReportsController` の `show` アクション修正
5. ビューに言及元一覧を追加

---

## 1. マイグレーション作成・実行

```bash
bin/rails generate migration CreateReportLinks
```

生成されたファイルに以下を記述：

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

```bash
bin/rails db:migrate
```

---

## 2. `ReportLink` モデル作成

```bash
bin/rails generate model ReportLink --skip-migration
```

`app/models/report_link.rb` を編集：

```ruby
class ReportLink < ApplicationRecord
  belongs_to :source_report, class_name: 'Report'
  belongs_to :target_report, class_name: 'Report'

  validates :source_report_id, uniqueness: { scope: :target_report_id }
end
```

---

## 3. `Report` モデルに追記

`app/models/report.rb` に以下を追加：

```ruby
has_many :report_links_as_source, class_name: 'ReportLink',
                                  foreign_key: :source_report_id,
                                  dependent: :destroy
has_many :report_links_as_target, class_name: 'ReportLink',
                                  foreign_key: :target_report_id,
                                  dependent: :destroy

has_many :mentioned_reports,  through: :report_links_as_source, source: :target_report
has_many :mentioning_reports, through: :report_links_as_target, source: :source_report

after_save :sync_report_links

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
  end
end
```

### コールバックと削除の対応

| 操作 | 言及の同期方法 |
|---|---|
| 日報を新規作成 | `after_save` → `sync_report_links` |
| 日報を更新（URL追加・削除含む） | `after_save` → `sync_report_links` |
| 日報自体を削除 | `dependent: :destroy` |

---

## 4. `ReportsController` の `show` アクション修正

`app/controllers/reports_controller.rb` の `show` を以下に変更：

```ruby
def show
  @report = Report.find(params[:id])
  @mentioning_reports = @report.mentioning_reports.includes(:user)
end
```

---

## 5. ビューに言及元一覧を追加

`app/views/reports/show.html.erb` に追記：

```erb
<% if @mentioning_reports.any? %>
  <section>
    <h2>この日報を言及している日報</h2>
    <ul>
      <% @mentioning_reports.each do |report| %>
        <li>
          <%= link_to report.title, report %>
          （<%= report.user.name %>）
        </li>
      <% end %>
    </ul>
  </section>
<% end %>
```
