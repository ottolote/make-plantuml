## ADDED Requirements

### Requirement: GitHub Actions image validation
The project SHALL define a GitHub Actions workflow that builds the container image automatically for repository changes so maintainers can detect image regressions before release.

#### Scenario: Validate image on change
- **WHEN** a pull request or equivalent integration event updates the repository
- **THEN** GitHub Actions builds the container image and reports success or failure in the repository checks

### Requirement: GitHub Container Registry publication
The project SHALL publish release-ready container images to GitHub Container Registry (`ghcr.io`) through GitHub Actions using repository-managed authentication.

#### Scenario: Publish image from a release trigger
- **WHEN** a maintainer triggers the documented release condition for image publication
- **THEN** GitHub Actions builds the image and pushes it to `ghcr.io` under the repository-owned package name

### Requirement: Deterministic image tagging and metadata
The publish workflow SHALL apply documented tags and OCI metadata so users can discover versioned and source-linked images in `ghcr.io`.

#### Scenario: Inspect published package metadata
- **WHEN** a user or maintainer inspects the published package in `ghcr.io`
- **THEN** the image exposes the documented tags and links back to the source repository metadata

### Requirement: Least-privilege workflow permissions
The CI/CD workflows SHALL use the minimum GitHub Actions permissions needed to build and publish the image.

#### Scenario: Review workflow permissions
- **WHEN** a maintainer reviews the GitHub Actions workflow definitions
- **THEN** image publishing permissions are scoped only to the jobs that need to push packages
