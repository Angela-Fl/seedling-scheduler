class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :plant, null: false, foreign_key: true
      t.string :task_type
      t.date :due_date
      t.string :status
      t.text :notes

      t.timestamps
    end
  end
end
