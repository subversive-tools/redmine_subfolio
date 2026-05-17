# Redmine Subfolio Plugin

A Redmine plugin for visual portfolio management of projects. Displays projects in a kanban board grouped by status, adds a status badge to project overview pages, and lets authorized users move projects between statuses via drag and drop.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Redmine Version](https://img.shields.io/badge/Redmine-4.0%2B-red.svg)](https://www.redmine.org/)

## Features

- **Kanban board**: `{{portfolio}}` wiki macro renders subprojects as cards in status columns
- **Drag & drop**: move projects between status columns — changes persist immediately
- **Status badge**: colored tag next to the project name on the project overview page
- **Permission control**: only members with the *Manage project status* permission can change status values
- **Color coding**: status column colors driven by a suffix on the status value (`-p`, `-i`, `-d`)

## Requirements

- Redmine 4.0 or higher
- A **Project Status** custom field of type *List* (see Setup below)

## Installation

```bash
cd /path/to/redmine/plugins
git clone https://github.com/modoq/redmine_subfolio.git
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

Restart Redmine after installation.

## Setup

### 1. Create the custom field

Go to **Administration → Custom Fields → Projects → New custom field** and create:

| Setting | Value |
|---|---|
| Name | `Project Status` (exact spelling required) |
| Format | List |
| Used as filter | optional |

Add your status values. Append a suffix to control the column color:

| Suffix | Color | Meaning |
|---|---|---|
| `-p` | yellow | pool / backlog / planning |
| `-i` | blue | in progress / implementation |
| `-d` | green | done / delivered / closed |

**Example values:**
```
Ideas-p
Planning-p
Development-i
Review-i
Done-d
```

### 2. Assign the permission

Go to **Administration → Roles and permissions** and enable *Manage project status* for the roles that should be allowed to move projects on the kanban board.

## Usage

### Kanban board

Place the macro on any wiki page within a parent project:

```
{{portfolio}}
```

All active, visible subprojects are shown as cards grouped by their *Project Status* value. Projects without a status appear in a separate *No Status* column. Members with the *Manage project status* permission can drag cards between columns.

### Status badge

When a subproject has a *Project Status* value set, a colored badge is automatically added next to the project name on the project overview page. The raw custom field entry is hidden — the badge replaces it.

## Compatibility

Tested with Redmine 4.x, 5.x, and 6.x. The plugin uses no Redmine-version-specific APIs beyond the standard hook and macro system.

## Migration from redmine_submenus

If you previously used the combined `redmine_submenus` plugin (before the kanban functionality was split out), run the migration to preserve role permissions:

```bash
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

The migration reads the old `kanban_allowed_roles` setting and grants the *Manage project status* permission to the corresponding roles automatically.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes
4. Open a pull request

## License

[MIT License](LICENSE) — Copyright (c) 2025 Stefan Mischke
