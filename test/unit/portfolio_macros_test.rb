require_relative '../test_helper'

class PortfolioMacrosTest < ActiveSupport::TestCase
  def setup
    @project = Project.create!(
      name:       "PortfolioTest-#{SecureRandom.hex(4)}",
      identifier: "portfolio-test-#{SecureRandom.hex(4)}"
    )
    @status_field = ProjectCustomField.create!(
      name:             'Project Status',
      field_format:     'list',
      possible_values:  %w[Planning-p Development-i Done-d]
    )
  end

  def teardown
    @status_field.destroy if @status_field&.persisted?
    @project.destroy      if @project&.persisted?
  end

  def test_warning_rendered_without_status_custom_field
    @status_field.destroy
    html = render_macro(:portfolio, @project, [])
    assert_match 'WARNING', html
  ensure
    @status_field = ProjectCustomField.create!(
      name:            'Project Status',
      field_format:    'list',
      possible_values: %w[Planning-p Development-i Done-d]
    )
  end

  def test_no_subprojects_message
    html = render_macro(:portfolio, @project, [])
    assert_match 'No active subprojects', html
  end

  def test_kanban_board_rendered_with_subprojects
    child = Project.create!(
      name:       'Child',
      identifier: "child-folio-#{SecureRandom.hex(4)}",
      parent:     @project,
      status:     Project::STATUS_ACTIVE
    )
    child.custom_field_values = { @status_field.id => 'Planning-p' }
    child.save!

    html = render_macro(:portfolio, @project, [])
    assert_match 'kanban-board', html
    assert_match 'Planning',     html
  ensure
    child&.destroy
  end

  def test_no_status_column_appears_for_unassigned_projects
    child = Project.create!(
      name:       'Unassigned',
      identifier: "child-folio-unassigned-#{SecureRandom.hex(4)}",
      parent:     @project,
      status:     Project::STATUS_ACTIVE
    )

    html = render_macro(:portfolio, @project, [])
    assert_match 'No Status', html
  ensure
    child&.destroy
  end

  private

  def render_macro(name, project, args)
    view = ApplicationController.new.view_context
    view.extend(Redmine::WikiFormatting::Macros::Definitions)
    view.instance_variable_set(:@project, project)
    view.instance_variable_set(:@user, User.current || User.anonymous)
    view.send("macro_#{name}", nil, args)
  rescue => e
    "error: #{e.message}"
  end
end
