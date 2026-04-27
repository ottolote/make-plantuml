## ADDED Requirements

### Requirement: Containerized render command
The tool SHALL provide a containerized command that renders all `*.pu` files discovered recursively within a mounted workspace directory into `svg` and `png` outputs without requiring PlantUML or Java on the host.

#### Scenario: Render a mounted workspace
- **WHEN** a user runs the published container image against a mounted workspace in one-shot render mode
- **THEN** the tool renders all discovered `*.pu` files in that workspace to `svg` and `png` outputs using the documented output layout

### Requirement: Containerized watch command
The tool SHALL provide a watch mode in the container image that performs an initial render and then re-renders affected diagrams when `*.pu` files change within the mounted workspace.

#### Scenario: Start watch mode
- **WHEN** a user starts the container in watch mode against a mounted workspace containing PlantUML files
- **THEN** the tool performs an initial render before entering a long-running watch loop

#### Scenario: Re-render after a source change
- **WHEN** a watched `*.pu` file is created or modified in the mounted workspace
- **THEN** the tool re-runs the render workflow and refreshes generated outputs for the changed workspace state

### Requirement: Host-compatible file ownership
The tool SHALL support a documented container runtime pattern that preserves host-compatible ownership for generated files written to bind-mounted directories.

#### Scenario: Run with caller UID and GID
- **WHEN** a user runs the container with the documented user-mapping configuration on a bind-mounted workspace
- **THEN** generated output files are writable and removable by that host user without manual ownership repair

### Requirement: Predictable workspace and output paths
The tool SHALL operate against a documented workspace mount path and SHALL write generated assets to a predictable output location that does not require repository-specific paths inside the container.

#### Scenario: Use the documented default layout
- **WHEN** a user follows the documented container invocation for a generic mounted folder
- **THEN** the tool reads sources from the documented workspace path and writes outputs to the documented default output tree for that workspace
