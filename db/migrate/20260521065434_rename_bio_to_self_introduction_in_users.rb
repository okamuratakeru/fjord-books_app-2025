class RenameBioToSelfIntroductionInUsers < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :bio, :self_introduction
  end
end
