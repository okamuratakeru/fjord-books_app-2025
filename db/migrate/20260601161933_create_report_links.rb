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
