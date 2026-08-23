class EnableRowLevelSecurityOnFolders < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE folders ENABLE ROW LEVEL SECURITY;
      ALTER TABLE folders FORCE ROW LEVEL SECURITY;

      CREATE POLICY tenant_isolation ON folders
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::bigint
          OR current_setting('app.bypass_rls', true) = 'on'
        );
    SQL
  end

  def down
    execute <<~SQL
      DROP POLICY IF EXISTS tenant_isolation ON folders;
      ALTER TABLE folders NO FORCE ROW LEVEL SECURITY;
      ALTER TABLE folders DISABLE ROW LEVEL SECURITY;
    SQL
  end
end
