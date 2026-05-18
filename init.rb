require 'redmine'

Redmine::Plugin.register :redmine_subfolio do
  name 'Subfolio'
  author 'Stefan Mischke'
  description 'Portfolio management for Redmine projects: kanban board, project status tags, and drag-and-drop status management via a custom Project Status field.'
  version '0.1.0'
  url 'https://github.com/subversive-tools/redmine_subfolio'
  author_url 'https://github.com/modoq'

  permission :manage_project_status, { kanban_projects: [:update_status] }, require: :member

  Rails.configuration.to_prepare do
    require_dependency 'portfolio_macros'
    require_dependency 'project_status_tag_hook'
    require_dependency 'project_status_field_hook'
    require_dependency 'project_status_control_patch'
    require_dependency 'project_status_view_patch'
  end
end
