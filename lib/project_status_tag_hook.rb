class ProjectStatusTagHook < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(context = {})
    stylesheet_link_tag 'subfolio.css', plugin: 'redmine_subfolio'
  rescue
    css_path = File.join(File.dirname(__FILE__), '..', 'assets', 'stylesheets', 'subfolio.css')
    File.exist?(css_path) ? "<style type='text/css'>#{File.read(css_path)}</style>".html_safe : ""
  end

  def view_projects_show_left(context = {})
    project = context[:project]
    return "" unless project

    field = SubfolioSettings.status_field
    return "" unless field

    status_value = project.custom_field_value(field)
    return "" unless status_value.present?

    display_name = status_value.gsub(/-[pid]$/, '')
    meta_class = case status_value
                 when /-p$/ then 'meta-pool'
                 when /-i$/ then 'meta-implementation'
                 when /-d$/ then 'meta-done'
                 else ''
                 end

    render_status_tag_script(display_name, meta_class, field.id)
  end

  private

  def render_status_tag_script(display_name, meta_class, field_id)
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
