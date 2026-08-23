class EnableRowLevelSecurityOnEvents < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE events ENABLE ROW LEVEL SECURITY;
      ALTER TABLE events FORCE ROW LEVEL SECURITY;

      CREATE POLICY tenant_isolation ON events
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::bigint
          OR current_setting('app.bypass_rls', true) = 'on'
        );
    SQL
  end

  def down
    execute <<~SQL
      DROP POLICY IF EXISTS tenant_isolation ON events;
      ALTER TABLE events NO FORCE ROW LEVEL SECURITY;
      ALTER TABLE events DISABLE ROW LEVEL SECURITY;
    SQL
  end
end
