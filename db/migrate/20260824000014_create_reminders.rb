class CreateReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :reminders do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :subject, polymorphic: true
      t.datetime :remind_at, null: false
      t.string :message, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :reminders, [ :status, :remind_at ]
  end
end
