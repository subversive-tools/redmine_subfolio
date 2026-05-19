require_relative '../test_helper'

class KanbanProjectsControllerTest < Redmine::ControllerTest
  fixtures :roles, :members, :member_roles, :enabled_modules

  def setup
    @project = Project.create!(
      name:       "KanbanTest-#{SecureRandom.hex(4)}",
      identifier: "kanban-test-#{SecureRandom.hex(4)}"
    )
    # Enable redmine_subfolio module so manage_project_status permission is accessible.
    # Redmine's authorization checks both the permission AND the project module; without
    # the module enabled, allowed_to?(:manage_project_status, @project) always returns false.
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
    @admin = User.find_by(admin: true) || begin
      User.create!(
        login: "admin-#{SecureRandom.hex(4)}", firstname: 'Admin', lastname: 'User',
        mail: "admin-#{SecureRandom.hex(4)}@example.com", admin: true
      )
    end
    @jsmith = User.find_by(login: 'jsmith') || begin
      User.create!(
        login: "jsmith-#{SecureRandom.hex(4)}", firstname: 'John', lastname: 'Smith',
        mail: "jsmith-#{SecureRandom.hex(4)}@example.com", admin: false
      )
    end
  end

  def teardown
    @status_field.destroy if @status_field&.persisted?
    @project.destroy      if @project&.persisted?
  end

  def test_update_status_requires_login
    # Unauthenticated requests are rejected by Redmine's authorization layer
    patch :update_status, params: { id: @project.id, status: 'Planning-p' }, as: :json
    assert_response :forbidden
  end

  def test_update_status_forbidden_without_permission
    @request.session[:user_id] = @jsmith.id
    patch :update_status, params: { id: @project.id, status: 'Planning-p' }, as: :json
    assert_response :forbidden
  end

  def test_update_status_success
    # Admin users bypass all permission checks in Redmine
    @request.session[:user_id] = @admin.id

    patch :update_status, params: { id: @project.id, status: 'Development-i' }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body['success'], "expected success but got: #{body.inspect}"
  end

  def test_project_not_found
    @request.session[:user_id] = @admin.id
    patch :update_status, params: { id: 999_999, status: 'Planning-p' }, as: :json
    # Redmine's authorization layer returns 403 for inaccessible/non-existent projects
    assert_response :forbidden
  end
end
