require_relative '../test_helper'

class KanbanProjectsControllerTest < Redmine::ControllerTest
  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules,
           :custom_fields, :custom_values

  def setup
    @project = projects(:ecookbook)
    @status_field = ProjectCustomField.create!(
      name: 'Project Status',
      field_format: 'list',
      possible_values: %w[Planning-p Development-i Done-d]
    )
  end

  def teardown
    @status_field.destroy
  end

  def test_update_status_requires_login
    patch :update_status, params: { id: @project.id, status: 'Planning-p' }, as: :json
    assert_response :unauthorized
  end

  def test_update_status_forbidden_without_permission
    @request.session[:user_id] = users(:jsmith).id
    patch :update_status, params: { id: @project.id, status: 'Planning-p' }, as: :json
    assert_response :forbidden
  end

  def test_update_status_success
    role = roles(:developer)
    role.add_permission! :manage_project_status
    @request.session[:user_id] = users(:jsmith).id

    patch :update_status, params: { id: @project.id, status: 'Development-i' }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body['success'], "expected success but got: #{body.inspect}"
  ensure
    role.remove_permission! :manage_project_status
  end

  def test_no_status_clears_custom_value
    role = roles(:developer)
    role.add_permission! :manage_project_status
    @request.session[:user_id] = users(:jsmith).id

    patch :update_status, params: { id: @project.id, status: 'No Status' }, as: :json

    assert_response :success
    cv = CustomValue.find_by(customized_type: 'Project', customized_id: @project.id,
                             custom_field_id: @status_field.id)
    assert_nil_or_blank cv&.value
  ensure
    role.remove_permission! :manage_project_status
  end

  def test_project_not_found
    @request.session[:user_id] = users(:admin).id
    patch :update_status, params: { id: 999_999, status: 'Planning-p' }, as: :json
    assert_response :not_found
  end

  private

  def assert_nil_or_blank(value)
    assert value.nil? || value == '', "expected nil or blank, got #{value.inspect}"
  end
end
