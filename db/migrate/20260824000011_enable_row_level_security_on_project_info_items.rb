class EnableRowLevelSecurityOnProjectInfoItems < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE project_info_items ENABLE ROW LEVEL SECURITY;
      ALTER TABLE project_info_items FORCE ROW LEVEL SECURITY;

      CREATE POLICY tenant_isolation ON project_info_items
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::bigint
          OR current_setting('app.bypass_rls', true) = 'on'
        );
    SQL
  end

  def down
    execute <<~SQL
      DROP POLICY IF EXISTS tenant_isolation ON project_info_items;
      ALTER TABLE project_info_items NO FORCE ROW LEVEL SECURITY;
      ALTER TABLE project_info_items DISABLE ROW LEVEL SECURITY;
    SQL
  end
end
