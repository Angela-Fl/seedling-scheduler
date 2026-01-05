class AddWantsReplyToFeedbackSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :feedback_submissions, :wants_reply, :boolean, default: false, null: false
  end
end
