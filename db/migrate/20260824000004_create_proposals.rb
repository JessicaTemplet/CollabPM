class CreateProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :proposals do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :assignee, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "proposed"
      t.date :due_date

      t.timestamps
    end

    add_index :proposals, [ :tenant_id, :status ]
    add_index :proposals, [ :tenant_id, :assignee_id ]
  end
end
