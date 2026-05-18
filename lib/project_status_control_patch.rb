module ProjectStatusControlPatch
  def self.included(base)
    base.class_eval do
      alias_method :update_without_status_check, :update
      alias_method :update, :update_with_status_check
    end
  end

  def update_with_status_check
    if params[:project] && params[:project][:custom_field_values]
      field = SubfolioSettings.status_field
      if field && params[:project][:custom_field_values].key?(field.id.to_s)
        unless User.current.allowed_to?(:manage_project_status, @project)
          flash[:error] = l(:notice_not_authorized_to_change_project_status)
          redirect_to settings_project_path(@project)
          return
        end
      end
    end

    update_without_status_check
  end
end

unless ProjectsController.included_modules.include?(ProjectStatusControlPatch)
  ProjectsController.send(:include, ProjectStatusControlPatch)
end
