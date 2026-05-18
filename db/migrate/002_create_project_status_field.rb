class CreateProjectStatusField < ActiveRecord::Migration[6.1]
  FIELD_NAME = 'Project Status'.freeze
  FIELD_DESCRIPTION = "=============================\nManaged by Subfolio plugin\n⚠️ Do not delete or rename ⚠️\n=============================".freeze
  DEFAULT_VALUES = ['Backlog-p', 'In Progress-i', 'Done-d'].freeze

  def up
    # Re-use existing field if admin already created one manually (old setup)
    field = CustomField.find_by(
      type: 'ProjectCustomField',
      name: FIELD_NAME,
      field_format: 'list'
    )

    unless field
      field = ProjectCustomField.create!(
        name: FIELD_NAME,
        description: FIELD_DESCRIPTION,
        field_format: 'list',
        possible_values: DEFAULT_VALUES,
        is_for_all: true,
        searchable: true,
        editable: true,
        visible: true
      )
    end

    settings = Setting.plugin_redmine_subfolio || {}
    settings['status_field_id'] = field.id.to_s
    Setting.plugin_redmine_subfolio = settings

    puts "Subfolio: Project Status field ready (ID #{field.id})"
  end

  def down
    settings = Setting.plugin_redmine_subfolio || {}
    field_id = settings['status_field_id'].to_i

    if field_id > 0
      field = CustomField.find_by(id: field_id, description: FIELD_DESCRIPTION)
      if field
        field.destroy
        puts "Subfolio: Project Status field removed (ID #{field_id})"
      else
        puts "Subfolio: Field ID #{field_id} not found or was manually modified – skipping delete"
      end
      settings.delete('status_field_id')
      Setting.plugin_redmine_subfolio = settings
    end
  end
end
