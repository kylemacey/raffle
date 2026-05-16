class CreateFeedbackReports < ActiveRecord::Migration[7.0]
  def change
    create_table :feedback_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :user_name, null: false
      t.jsonb :role_keys, null: false, default: []
      t.string :report_type, null: false
      t.text :message, null: false
      t.string :current_path, null: false
      t.string :referrer
      t.string :user_agent
      t.string :remote_ip
      t.jsonb :browser_metadata, null: false, default: {}
      t.string :contact_name
      t.string :contact_email

      t.timestamps
    end

    add_index :feedback_reports, :created_at
    add_index :feedback_reports, :report_type
  end
end
