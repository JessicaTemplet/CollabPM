class EnableRowLevelSecurityOnActivityLogs < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
      ALTER TABLE activity_logs FORCE ROW LEVEL SECURITY;

      CREATE POLICY tenant_isolation ON activity_logs
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::bigint
          OR current_setting('app.bypass_rls', true) = 'on'
        );
    SQL
  end

  def down
    execute <<~SQL
      DROP POLICY IF EXISTS tenant_isolation ON activity_logs;
      ALTER TABLE activity_logs NO FORCE ROW LEVEL SECURITY;
      ALTER TABLE activity_logs DISABLE ROW LEVEL SECURITY;
    SQL
  end
end
