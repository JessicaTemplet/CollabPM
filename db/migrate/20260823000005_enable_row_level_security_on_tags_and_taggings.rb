class EnableRowLevelSecurityOnTagsAndTaggings < ActiveRecord::Migration[8.1]
  # Same pattern as users/invites/comments — see
  # 20260818000005_enable_row_level_security_on_users.rb for the full
  # rationale. Not inherited from those tables; repeated per tenant-owned table.
  def up
    execute <<~SQL
      ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
      ALTER TABLE tags FORCE ROW LEVEL SECURITY;

      CREATE POLICY tenant_isolation ON tags
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::bigint
          OR current_setting('app.bypass_rls', true) = 'on'
        );

      ALTER TABLE taggings ENABLE ROW LEVEL SECURITY;
      ALTER TABLE taggings FORCE ROW LEVEL SECURITY;

      CREATE POLICY tenant_isolation ON taggings
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::bigint
          OR current_setting('app.bypass_rls', true) = 'on'
        );
    SQL
  end

  def down
    execute <<~SQL
      DROP POLICY IF EXISTS tenant_isolation ON taggings;
      ALTER TABLE taggings NO FORCE ROW LEVEL SECURITY;
      ALTER TABLE taggings DISABLE ROW LEVEL SECURITY;

      DROP POLICY IF EXISTS tenant_isolation ON tags;
      ALTER TABLE tags NO FORCE ROW LEVEL SECURITY;
      ALTER TABLE tags DISABLE ROW LEVEL SECURITY;
    SQL
  end
end
