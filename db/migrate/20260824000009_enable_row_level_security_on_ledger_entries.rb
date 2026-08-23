class EnableRowLevelSecurityOnLedgerEntries < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE ledger_entries ENABLE ROW LEVEL SECURITY;
      ALTER TABLE ledger_entries FORCE ROW LEVEL SECURITY;

      CREATE POLICY tenant_isolation ON ledger_entries
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::bigint
          OR current_setting('app.bypass_rls', true) = 'on'
        );
    SQL
  end

  def down
    execute <<~SQL
      DROP POLICY IF EXISTS tenant_isolation ON ledger_entries;
      ALTER TABLE ledger_entries NO FORCE ROW LEVEL SECURITY;
      ALTER TABLE ledger_entries DISABLE ROW LEVEL SECURITY;
    SQL
  end
end
