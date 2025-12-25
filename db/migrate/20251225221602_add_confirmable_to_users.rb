class AddConfirmableToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    add_index :users, :confirmation_token, unique: true

    # Auto-confirm existing users (they registered before email confirmation was required)
    User.update_all(confirmed_at: Time.now) if User.table_exists?
  end
end
