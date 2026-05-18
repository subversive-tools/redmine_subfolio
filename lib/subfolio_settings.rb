module SubfolioSettings
  FIELD_NAME = 'Project Status'.freeze
  FIELD_DESCRIPTION = "=============================\nManaged by Subfolio plugin\n⚠️ Do not delete or rename ⚠️\n=============================\n\nPossible Values = Kanban-Spalten.\nFarbkodierung per Suffix:\n  -p  Pool / Backlog\n  -i  In Arbeit (In Progress)\n  -d  Erledigt (Done)\n\nBeispiel: \"In Arbeit-i\"".freeze
  DEFAULT_VALUES = ['Backlog-p', 'In Progress-i', 'Done-d'].freeze

  def self.status_field
    field_id = Setting.plugin_redmine_subfolio['status_field_id'].to_i
    field = field_id > 0 ? CustomField.find_by(id: field_id, type: 'ProjectCustomField', field_format: 'list') : nil
    field || recreate_status_field
  end

  def self.recreate_status_field
    # Re-adopt an existing field with the same name before creating a new one
    field = CustomField.find_by(type: 'ProjectCustomField', field_format: 'list', name: FIELD_NAME)
    field ||= ProjectCustomField.create!(
      name: FIELD_NAME,
      description: FIELD_DESCRIPTION,
      field_format: 'list',
      possible_values: DEFAULT_VALUES,
      is_for_all: true,
      searchable: true,
      editable: true,
      visible: true
    )
    settings = Setting.plugin_redmine_subfolio || {}
    settings['status_field_id'] = field.id.to_s
    Setting.plugin_redmine_subfolio = settings
    Rails.logger.info "Subfolio: Project Status field (re)adopted (ID #{field.id})"
    field
  rescue => e
    Rails.logger.error "Subfolio: Failed to recreate Project Status field – #{e.message}"
    nil
  end
end
