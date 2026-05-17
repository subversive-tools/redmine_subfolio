class ProjectStatusTagHook < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(context = {})
    begin
      stylesheet_link_tag 'subfolio.css', plugin: 'redmine_subfolio'
    rescue
      css_path = File.join(File.dirname(__FILE__), '..', 'assets', 'stylesheets', 'subfolio.css')
      if File.exist?(css_path)
        "<style type='text/css'>#{File.read(css_path)}</style>".html_safe
      else
        ""
      end
    end
  end

  def view_projects_show_left(context = {})
    project = context[:project]
    return "" unless project

    status_value = get_project_status_value(project)
    return "" unless status_value.present?

    display_name = status_value.gsub(/-[pid]$/, '')
    meta_class = parse_meta_class(status_value)

    render_status_tag_script(display_name, meta_class)
  end

  private

  def get_project_status_value(project)
    field = CustomField.where(
      type: 'ProjectCustomField',
      name: 'Project Status',
      field_format: 'list'
    ).first
    return nil unless field
    project.custom_field_value(field)
  end

  def parse_meta_class(status_value)
    case status_value
    when /-p$/ then 'meta-pool'
    when /-i$/ then 'meta-implementation'
    when /-d$/ then 'meta-done'
    else ''
    end
  end

  def render_status_tag_script(display_name, meta_class)
    <<~HTML
      <script>
        (function() {
          const existingTags = document.querySelectorAll('.project-status-tag');
          existingTags.forEach(function(tag) { tag.remove(); });

          function addStatusTag() {
            const h2 = document.querySelector('#content h2');
            if (h2 && !h2.querySelector('.project-status-tag')) {
              const tag = document.createElement('span');
              tag.className = 'project-status-tag #{meta_class}';
              tag.textContent = '#{display_name.gsub("'", "\\'")}';
              h2.appendChild(tag);
              hideCustomField();
            }
          }

          function hideCustomField() {
            document.querySelectorAll('li.list_cf span.label').forEach(function(label) {
              if (label.textContent.trim() === 'Project Status:') {
                label.closest('li').style.display = 'none';
              }
            });
          }

          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', addStatusTag);
          } else {
            addStatusTag();
          }
        })();
      </script>
    HTML
  end
end
