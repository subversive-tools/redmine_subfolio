require_relative '../test_helper'

class KanbanProjectsControllerTest < Redmine::ControllerTest
  fixtures :roles, :members, :member_roles, :enabled_modules

  def setup
    @project = Project.create!(
      name:       "KanbanTest-#{SecureRandom.hex(4)}",
      identifier: "kanban-test-#{SecureRandom.hex(4)}"
    )
    @status_field = ProjectCustomField.create!(
      name:            'Project Status',
      field_format:    'list',
      possible_values: %w[Planning-p Development-i Done-d]
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
    patch :update_status, params: { id: @project.id, status: 'Planning-p' }, as: :json
    assert_response :unauthorized
  end

  def test_update_status_forbidden_without_permission
    @request.session[:user_id] = @jsmith.id
    patch :update_status, params: { id: @project.id, status: 'Planning-p' }, as: :json
    assert_response :forbidden
  end

  def test_update_status_success
    role = Role.find_by(name: 'Manager') || Role.create!(name: 'Manager', permissions: [])
    role.add_permission! :manage_project_status
    Member.create!(project: @project, user: @jsmith,
                   roles: [role]) unless @project.members.exists?(user: @jsmith)
    @request.session[:user_id] = @jsmith.id

    patch :update_status, params: { id: @project.id, status: 'Development-i' }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body['success'], "expected success but got: #{body.inspect}"
  ensure
    role.remove_permission! :manage_project_status rescue nil
  end

  def test_project_not_found
    @request.session[:user_id] = @admin.id
    patch :update_status, params: { id: 999_999, status: 'Planning-p' }, as: :json
    assert_response :not_found
  end
end
