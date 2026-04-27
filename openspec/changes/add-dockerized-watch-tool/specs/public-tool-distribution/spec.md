## ADDED Requirements

### Requirement: Publishable container distribution
The project SHALL define a release-ready Docker image build and runtime contract suitable for public distribution as the primary supported interface for rendering PlantUML diagrams.

#### Scenario: Build the public image
- **WHEN** a maintainer builds the project for release
- **THEN** the repository produces a documented Docker image with a stable command interface for render and watch operations

### Requirement: Official-upstream-based runtime
The released container image SHALL use official upstream PlantUML assets where practical, or a thin derivative image that clearly documents any additional dependencies required for watch mode.

#### Scenario: Inspect runtime provenance
- **WHEN** a maintainer reviews the image build definition
- **THEN** the PlantUML runtime source and any added watch dependencies are explicit and maintainable

### Requirement: Public usage documentation
The project SHALL include user-facing documentation for building, running, and troubleshooting the containerized tool, including mounted-volume examples for one-shot rendering and watch mode.

#### Scenario: Follow documented render usage
- **WHEN** a new user follows the published Docker usage example for one-shot rendering
- **THEN** they can render diagrams from a mounted folder without consulting the internal Makefile implementation

#### Scenario: Follow documented watch usage
- **WHEN** a new user follows the published Docker usage example for watch mode
- **THEN** they can keep a mounted folder under continuous rendering with clear expectations for stop behavior and output location

### Requirement: Backwards-compatible maintainer workflow
The project SHALL drop legacy repository wrapper scripts/Makefiles for building the image and exclusively document cloud-native `docker build` and `docker run` commands as the maintainer-oriented local workflow. An internal `Makefile` may be kept purely for optimizing the PlantUML rendering loop inside the container.

#### Scenario: Maintainer uses local automation
- **WHEN** a contributor works inside the repository
- **THEN** they use raw Docker commands to build and run the tool, exactly matching the production use-cases without relying on wrapper scripts.
