class CreateLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_entries do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :subject, polymorphic: true
      t.string :method, null: false # "hourly" | "deliverable"
      t.string :entry_type, null: false # "value" | "payment"
      # Snapshotted at creation, never recomputed later — see corrections
      # note on the model. Integer cents, not a decimal dollar amount, to
      # avoid float/decimal rounding drift across many entries.
      t.integer :amount_cents, null: false
      t.text :description

      t.datetime :created_at, null: false
    end

    add_index :ledger_entries, [ :tenant_id, :entry_type ]
    add_index :ledger_entries, [ :subject_type, :subject_id ]
  end
end
