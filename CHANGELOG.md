# Changelog

All notable changes to this project will be documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.2.0] - 2026-05-18

### Added
- **Auto-setup**: the *Project Status* custom field is now created automatically when running migrations — no manual admin configuration required.
- **Self-healing**: if the custom field is ever deleted, the plugin re-creates or re-adopts it on the next request.
- **Plugin settings page**: shows the active custom field with a direct link to edit it (`Administration → Plugins → Subfolio`).
- **SubfolioSettings module**: centralised lookup by field ID instead of hardcoded field name — robust against renaming.
- **Custom field description**: includes a visible warning and suffix guide for admins managing the field.

### Fixed
- Replaced `require_dependency` with `require_relative` so macros and hooks load correctly under Rails 7 / Ruby 3.
- Migration 001 no longer crashes when `redmine_submenus` is not installed (leftover from the original plugin split).

## [0.1.0] - 2026-05-18

### Added
- Initial release extracted from `redmine_submenus`.
- `{{portfolio}}` wiki macro renders subprojects as a kanban board grouped by *Project Status*.
- Drag-and-drop status changes between columns, persisted immediately.
- Coloured status badge next to the project name on the project overview page.
- Permission `manage_project_status` controls who can move projects.
- Colour coding via `-p` (backlog), `-i` (in progress), `-d` (done) suffixes on status values.
