class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :notifiable, polymorphic: true
      t.string :kind, null: false
      t.string :message, null: false
      t.datetime :read_at

      t.datetime :created_at, null: false
    end

    add_index :notifications, [ :recipient_id, :read_at ]
  end
end
