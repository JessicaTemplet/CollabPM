class EnableRowLevelSecurityOnNotifications < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
      ALTER TABLE notifications FORCE ROW LEVEL SECURITY;

      CREATE POLICY tenant_isolation ON notifications
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::bigint
          OR current_setting('app.bypass_rls', true) = 'on'
        );
    SQL
  end

  def down
    execute <<~SQL
      DROP POLICY IF EXISTS tenant_isolation ON notifications;
      ALTER TABLE notifications NO FORCE ROW LEVEL SECURITY;
      ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
    SQL
  end
end
