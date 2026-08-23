class CreateInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :invites do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :used_by, foreign_key: { to_table: :users }

      t.string :role, null: false, default: "member" # "admin" | "member" — never "owner", that's bootstrap-only
      t.integer :generation_limit, null: false, default: 3 # caps how many times A -> B -> C -> ... forwarding can hop
      t.datetime :expires_at, null: false
      t.datetime :used_at # nil = still redeemable; set once, atomically, on registration

      # History of forward hops (NOT identity — the person forwarding hasn't
      # registered yet, so there's no User row to reference). Each entry:
      # {"generation" => n, "forwarded_at" => iso8601}. Purely an audit trail;
      # redemption eligibility is decided by used_at/expires_at/generation_limit,
      # never by what's in this log.
      t.jsonb :forward_log, null: false, default: []

      t.timestamps
    end

    add_index :invites, [ :tenant_id, :used_at ]
  end
end
