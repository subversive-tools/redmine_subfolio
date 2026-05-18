class ProjectStatusFieldHook < Redmine::Hook::ViewListener
  def view_projects_form(context = {})
    project = context[:project]

    field = SubfolioSettings.status_field
    return '' unless field
    return '' if User.current.allowed_to?(:manage_project_status, project)

    field_id = "project_custom_field_values_#{field.id}"
    <<~HTML
      <script type="text/javascript">
        document.addEventListener('DOMContentLoaded', function() {
          var field = document.getElementById('#{field_id}');
          if (field) {
            var container = field.closest('p, div, .field, tr');
            if (container) container.style.display = 'none';
          }
          document.querySelectorAll('label[for="#{field_id}"]').forEach(function(label) {
            var container = label.closest('p, div, .field, tr');
            if (container) container.style.display = 'none';
          });
        });
      </script>
    HTML
  end
end
