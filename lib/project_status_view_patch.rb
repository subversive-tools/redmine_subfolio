module ProjectStatusViewPatch
  def self.included(base)
    base.class_eval do
      def show_project_status_field?(project)
        User.current.allowed_to?(:manage_project_status, project)
      end
    end
  end
end

unless ApplicationHelper.included_modules.include?(ProjectStatusViewPatch)
  ApplicationHelper.send(:include, ProjectStatusViewPatch)
end
