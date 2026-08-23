class EnableRowLevelSecurityOnComments < ActiveRecord::Migration[8.1]
  # Same pattern as users/invites — see 20260818000005_enable_row_level_security_on_users.rb
  # for the full rationale. Not inherited from those tables; repeated per tenant-owned table.
  def up
    execute <<~SQL
      ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
      ALTER TABLE comments FORCE ROW LEVEL SECURITY;

      CREATE POLICY tenant_isolation ON comments
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::bigint
          OR current_setting('app.bypass_rls', true) = 'on'
        );
    SQL
  end

  def down
    execute <<~SQL
      DROP POLICY IF EXISTS tenant_isolation ON comments;
      ALTER TABLE comments NO FORCE ROW LEVEL SECURITY;
      ALTER TABLE comments DISABLE ROW LEVEL SECURITY;
    SQL
  end
end
