class CreateFeedbackSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :feedback_submissions do |t|
      t.string :category, null: false
      t.text :message, null: false
      t.string :page
      t.string :email
      t.string :user_agent
      t.string :status, default: "new", null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :feedback_submissions, :status
    add_index :feedback_submissions, :created_at
  end
end
