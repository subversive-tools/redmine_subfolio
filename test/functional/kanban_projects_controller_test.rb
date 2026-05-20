require_relative '../test_helper'

class KanbanProjectsControllerTest < Redmine::ControllerTest
  # Redmine::ControllerTest does not declare fixtures :all — must be explicit.
  # Also: do NOT use `as: :json` for patch calls — Redmine's api_request? checks
  # params[:format] and skips session auth when it equals "json", causing 403.
  fixtures :all

  def setup
    @project = Project.create!(
      name:       "KanbanTest-#{SecureRandom.hex(4)}",
      identifier: "kanban-test-#{SecureRandom.hex(4)}"
    )
    # Enable redmine_subfolio module so manage_project_status permission is accessible.
    ActiveRecord::Base.connection.execute(
      "INSERT INTO enabled_modules (project_id, name) VALUES (#{@project.id}, 'redmine_subfolio')"
    )
    @project.reload

    @status_field = ProjectCustomField.create!(
      name:            'Project Status',
      field_format:    'list',
      possible_values: %w[Planning-p Development-i Done-d],
      is_for_all:      true
    )
    @admin  = User.find_by(login: 'admin')
    @jsmith = User.find_by(login: 'jsmith')
  end

  def teardown
    @status_field.destroy if @status_field&.persisted?
    @project.destroy      if @project&.persisted?
  end

  def test_update_status_requires_login
    # No session, JSON format: Redmine's require_login calls head :forbidden for
    # non-HTML formats.  Without as: :json the format is HTML and we'd get a 302
    # redirect to /login instead.  Using as: :json triggers api_request?=true
    # which skips session lookup (no session anyway), falls through to anonymous,
    # then require_login returns 403 for JSON format.
    patch :update_status, params: { id: @project.id, status: 'Planning-p' }, as: :json
    assert_response :forbidden
  end

  def test_update_status_forbidden_without_permission
    # jsmith has no role on @project → authorize_kanban_update returns 403 JSON
    @request.session[:user_id] = @jsmith.id
    patch :update_status, params: { id: @project.id, status: 'Planning-p' }
    assert_response :forbidden
  end

  def test_update_status_success
    # Admin bypasses all permission checks in Redmine
    @request.session[:user_id] = @admin.id
    patch :update_status, params: { id: @project.id, status: 'Development-i' }
    assert_response :success
    body = JSON.parse(response.body)
    assert body['success'], "expected success but got: #{body.inspect}"
  end

  def test_project_not_found
    # With valid auth, find_project rescues RecordNotFound and renders :not_found (404)
    @request.session[:user_id] = @admin.id
    patch :update_status, params: { id: 999_999, status: 'Planning-p' }
    assert_response :not_found
  end
end
