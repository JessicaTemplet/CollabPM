class EnableRowLevelSecurityOnProposals < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE proposals ENABLE ROW LEVEL SECURITY;
      ALTER TABLE proposals FORCE ROW LEVEL SECURITY;

      CREATE POLICY tenant_isolation ON proposals
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::bigint
          OR current_setting('app.bypass_rls', true) = 'on'
        );
    SQL
  end

  def down
    execute <<~SQL
      DROP POLICY IF EXISTS tenant_isolation ON proposals;
      ALTER TABLE proposals NO FORCE ROW LEVEL SECURITY;
      ALTER TABLE proposals DISABLE ROW LEVEL SECURITY;
    SQL
  end
end
