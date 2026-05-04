## Why

The current repository works as a local Makefile helper, but it still requires users to install Java, PlantUML, and `entr` themselves before `make watch` is useful. Packaging the workflow as a Docker-based tool makes it easier to adopt, safer to run across environments, and much closer to something that can be published as a polished public utility.

## What Changes

- Add a containerized workflow for rendering and watch mode so users can mount a diagram directory and render `*.pu` and `*.puml` files without local toolchain setup.
- Improve the runtime behavior for mounted volumes, including predictable output locations (defaulting to alongside source files) and host-compatible file ownership to avoid permission problems.
- Replace the current "download the jar and install dependencies yourself" setup with a more professional distribution story based on official upstream images where practical.
- Upgrade the repository to be fully cloud-native, dropping legacy bash wrapper scripts or Makefiles for building/testing the container in favor of direct `docker run ghcr.io/<owner>/make-plantuml:latest ...` usage.
- Retain a minimal internal `Makefile` strictly as a rendering optimization to avoid rebuilding unmodified PlantUML files inside the container runtime.
- Add GitHub Actions automation for building the public image and publishing release images to GitHub Container Registry (`ghcr.io`).

## Capabilities

### New Capabilities
- `dockerized-rendering-workflow`: Run one-shot rendering and watch mode from a Docker image against a mounted host workspace, while preserving usable output files on the host.
- `public-tool-distribution`: Package the project as a public-facing tool with release-ready documentation, ergonomic container commands, and a maintainable image/runtime layout.
- `container-release-automation`: Build, validate, and publish the Docker image through GitHub Actions to GitHub Container Registry for public consumption.

### Modified Capabilities
- None.

## Impact

- Affected code: `Makefile`, `watch.sh`, container/build assets, GitHub Actions workflows, documentation, and release-facing project metadata.
- Dependencies/systems: Docker image build and runtime, PlantUML/Java runtime selection, `entr`-based watch behavior, host/container UID-GID handling for mounted volumes, and GitHub Actions plus `ghcr.io` publishing.
- User workflows: local `make` usage will remain relevant, but the primary experience expands to documented `docker run` usage for rendering and watching diagrams in arbitrary mounted directories.
