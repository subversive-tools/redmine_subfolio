class MigrateKanbanPermissions < ActiveRecord::Migration[6.1]
  def up
    # Migrate from old combined redmine_submenus plugin: read kanban_allowed_roles setting
    plugin_settings = Setting.plugin_redmine_submenus || {}
    allowed_roles_setting = plugin_settings['kanban_allowed_roles']

    if allowed_roles_setting.present?
      allowed_roles_setting.split(',').map(&:strip).each do |role_name|
        role = Role.find_by(name: role_name)
        if role
          permissions = role.permissions || []
          unless permissions.include?(:manage_project_status)
            role.add_permission!(:manage_project_status)
            puts "Added 'manage_project_status' permission to role: #{role_name}"
          end
        else
          puts "Warning: Role '#{role_name}' not found - skipping"
        end
      end
    else
      manager_role = Role.find_by(name: 'Manager')
      if manager_role
        permissions = manager_role.permissions || []
        unless permissions.include?(:manage_project_status)
          manager_role.add_permission!(:manage_project_status)
          puts "Added 'manage_project_status' permission to default Manager role"
        end
      end
    end

    if plugin_settings.key?('kanban_allowed_roles')
      plugin_settings.delete('kanban_allowed_roles')
      Setting.plugin_redmine_submenus = plugin_settings
      puts "Removed deprecated 'kanban_allowed_roles' from plugin settings"
    end
  end

  def down
    Role.all.each do |role|
      if role.permissions&.include?(:manage_project_status)
        role.remove_permission!(:manage_project_status)
        puts "Removed 'manage_project_status' permission from role: #{role.name}"
      end
    end
  end
end
