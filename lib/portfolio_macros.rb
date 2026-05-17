require 'redmine'

module PortfolioMacros
  Redmine::WikiFormatting::Macros.register do
    desc "Displays a kanban board of subprojects grouped by the 'Project Status' custom field.

{{portfolio}} -- kanban view with subprojects as cards grouped by status (requires 'Project Status' custom field of type List)

Setup: Administration → Custom Fields → Projects → New field named 'Project Status' (type: List).
Status color coding: append -p (pool/backlog), -i (in progress), or -d (done) to status values."

    macro :portfolio do |obj, args|
      return '' unless @project

      render_kanban_view(@project)
    end

    private

    def render_kanban_view(project)
      project_status_field = CustomField.where(
        type: 'ProjectCustomField',
        name: 'Project Status',
        field_format: 'list'
      ).first

      unless project_status_field
        return "<div class='kanban-warning'>
                  <strong>WARNING:</strong> Portfolio view requires a custom field 'Project Status' of type 'List' for projects.
                  This can be set up by an administrator under <em>Administration → Custom Fields → Projects</em>.
                </div>".html_safe
      end

      active_subprojects = project.children.visible.where(status: Project::STATUS_ACTIVE)

      return "<p>No active subprojects found.</p>".html_safe if active_subprojects.empty?

      status_options = project_status_field.possible_values
      kanban_groups = {}
      status_options.each { |s| kanban_groups[s] = [] }

      projects_without_status = []

      active_subprojects.each do |subproject|
        status_value = subproject.custom_field_value(project_status_field)
        if status_value.present? && status_options.include?(status_value)
          kanban_groups[status_value] << subproject
        else
          projects_without_status << subproject
        end
      end

      html = "<div class='kanban-board'>"

      columns_order = []
      if projects_without_status.any?
        columns_order << "No Status"
        kanban_groups["No Status"] = projects_without_status
      end
      columns_order += status_options

      columns_order.each do |status|
        projects_in_status = kanban_groups[status] || []

        display_name = status
        meta_status_class = ""

        if status != "No Status" && status.match(/-([pid])$/)
          meta_suffix = $1
          display_name = status.gsub(/-[pid]$/, '')
          case meta_suffix
          when 'p' then meta_status_class = " meta-pool"
          when 'i' then meta_status_class = " meta-implementation"
          when 'd' then meta_status_class = " meta-done"
          end
        end

        html << "<div class='kanban-column#{meta_status_class}'>"
        html << "<h3>#{ERB::Util.html_escape(display_name)}</h3>"
        html << "<div class='kanban-cards' data-status='#{ERB::Util.html_escape(status)}'>"

        projects_in_status.each do |subproject|
          html << "<div class='kanban-card' data-project-id='#{subproject.id}'>"
          html << "<div class='card-title'>"
          html << link_to(subproject.name, params[:controller] == 'wiki' ? project_wiki_path(subproject) : project_path(subproject))
          html << "</div>"

          if subproject.description.present?
            html << "<div class='card-description'>"
            html << ERB::Util.html_escape(truncate(subproject.description, length: 100))
            html << "</div>"
          end

          if subproject.members.any?
            html << "<div class='card-members'>"
            html << "\u{1F465} " + subproject.members.limit(3).map { |m| m.user.name }.join(", ")
            html << (subproject.members.count > 3 ? " ..." : "")
            html << "</div>"
          end

          html << "</div>"
        end

        html << "</div>"
        html << "</div>"
      end

      html << "</div>"
      html << kanban_javascript
      html.html_safe
    end

    def kanban_javascript
      <<~JS
        <script>
          document.addEventListener('DOMContentLoaded', function() {
            const cards = document.querySelectorAll('.kanban-card');
            const columns = document.querySelectorAll('.kanban-cards');
            let draggedElement = null;

            cards.forEach(function(card) {
              card.draggable = true;

              card.addEventListener('dragstart', function(e) {
                draggedElement = this;
                e.dataTransfer.effectAllowed = 'move';
                e.dataTransfer.setData('text/plain', this.dataset.projectId);

                const dragImage = this.cloneNode(true);
                const rect = this.getBoundingClientRect();
                const styles = window.getComputedStyle(this);
                dragImage.style.width = rect.width + 'px';
                dragImage.style.height = rect.height + 'px';
                dragImage.style.boxSizing = styles.boxSizing;
                dragImage.style.padding = styles.padding;
                dragImage.style.border = styles.border;
                dragImage.className += ' dragging';
                dragImage.style.position = 'absolute';
                dragImage.style.top = '-1000px';
                dragImage.style.pointerEvents = 'none';
                document.body.appendChild(dragImage);
                e.dataTransfer.setDragImage(dragImage, 125, 60);
                setTimeout(function() {
                  if (document.body.contains(dragImage)) document.body.removeChild(dragImage);
                }, 100);

                this.classList.add('drag-placeholder');
              });

              card.addEventListener('dragend', function() {
                this.classList.remove('drag-placeholder');
                draggedElement = null;
              });
            });

            columns.forEach(function(column) {
              column.addEventListener('dragover', function(e) {
                e.preventDefault();
                e.dataTransfer.dropEffect = 'move';
                this.classList.add('drag-over');
              });

              column.addEventListener('dragenter', function(e) {
                e.preventDefault();
                this.classList.add('drag-over');
              });

              column.addEventListener('dragleave', function(e) {
                if (!this.contains(e.relatedTarget)) this.classList.remove('drag-over');
              });

              column.addEventListener('drop', function(e) {
                e.preventDefault();
                this.classList.remove('drag-over');

                if (!draggedElement) return;

                const projectId = draggedElement.dataset.projectId;
                const newStatus = this.dataset.status;
                const originalParent = draggedElement.parentNode;

                if (originalParent !== this) {
                  this.appendChild(draggedElement);
                  updateProjectStatus(projectId, newStatus, draggedElement, originalParent);
                }
              });
            });

            function updateProjectStatus(projectId, newStatus, cardElement, originalParent) {
              const csrfMeta = document.querySelector('meta[name="csrf-token"]');
              const token = csrfMeta ? csrfMeta.getAttribute('content') : '';

              fetch('/kanban_projects/' + projectId + '/update_status', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
                body: JSON.stringify({ status: newStatus })
              })
              .then(function(r) { return r.json(); })
              .then(function(data) {
                if (!data.success) {
                  if (originalParent && cardElement) originalParent.appendChild(cardElement);
                  alert('Error updating status: ' + data.error);
                }
              })
              .catch(function() {
                if (originalParent && cardElement) originalParent.appendChild(cardElement);
                alert('Network error updating status');
              });
            }
          });
        </script>
      JS
    end
  end
end
