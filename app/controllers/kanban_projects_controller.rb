class KanbanProjectsController < ApplicationController
  before_action :require_login
  before_action :find_project
  before_action :authorize_kanban_update

  def update_status
    field = SubfolioSettings.status_field

    unless field
      render json: { success: false, error: 'Project Status custom field not configured' }
      return
    end

    new_status = params[:status]
    allowed_statuses = field.possible_values + ["No Status"]

    unless allowed_statuses.include?(new_status)
      render json: { success: false, error: 'Invalid status value' }
      return
    end

    status_value = (new_status == "No Status") ? "" : new_status

    begin
      @project.custom_field_values = { field.id => status_value }
      if @project.save
        render json: { success: true }
      else
        render json: { success: false, error: @project.errors.full_messages.join(', ') }
      end
    rescue => e
      render json: { success: false, error: e.message }
    end
  end

  private

  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: 'Project not found' }
  end

  def authorize_kanban_update
    unless User.current.allowed_to?(:manage_project_status, @project)
      render json: { success: false, error: 'Insufficient permissions' }
    end
  end
end
