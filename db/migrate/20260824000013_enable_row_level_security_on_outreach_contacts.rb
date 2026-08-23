class EnableRowLevelSecurityOnOutreachContacts < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE outreach_contacts ENABLE ROW LEVEL SECURITY;
      ALTER TABLE outreach_contacts FORCE ROW LEVEL SECURITY;

      CREATE POLICY tenant_isolation ON outreach_contacts
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::bigint
          OR current_setting('app.bypass_rls', true) = 'on'
        );
    SQL
  end

  def down
    execute <<~SQL
      DROP POLICY IF EXISTS tenant_isolation ON outreach_contacts;
      ALTER TABLE outreach_contacts NO FORCE ROW LEVEL SECURITY;
      ALTER TABLE outreach_contacts DISABLE ROW LEVEL SECURITY;
    SQL
  end
end
