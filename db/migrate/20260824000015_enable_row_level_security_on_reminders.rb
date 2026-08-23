class EnableRowLevelSecurityOnReminders < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
      ALTER TABLE reminders FORCE ROW LEVEL SECURITY;

      CREATE POLICY tenant_isolation ON reminders
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::bigint
          OR current_setting('app.bypass_rls', true) = 'on'
        );
    SQL
  end

  def down
    execute <<~SQL
      DROP POLICY IF EXISTS tenant_isolation ON reminders;
      ALTER TABLE reminders NO FORCE ROW LEVEL SECURITY;
      ALTER TABLE reminders DISABLE ROW LEVEL SECURITY;
    SQL
  end
end
