## Context

The repository currently provides a local Makefile-based workflow that renders `*.pu` diagrams into `output/` and offers `make watch` through `entr`. The main friction points are local dependency setup, manual PlantUML jar management, and container-host permission issues that appear as soon as this workflow is moved into Docker with bind mounts.

This change turns the project into a release-ready containerized tool while preserving the existing simple model: discover PlantUML sources recursively, render deterministic outputs, and support continuous watch mode. The design needs to support both one-shot rendering and long-running watch usage against arbitrary mounted folders, preferably using official upstream images for the PlantUML runtime instead of maintaining a custom Java-plus-jar stack from scratch.

The release story also needs first-party automation: the public image should be built and published through GitHub Actions so maintainers can cut releases consistently and users can pull a trusted image from GitHub Container Registry.

## Goals / Non-Goals

**Goals:**
- Provide a Docker image that can render and watch mounted directories without requiring Java or PlantUML on the host.
- Ensure generated `png`/`svg` files are written with host-compatible ownership so users do not end up with root-owned artifacts.
- Preserve the current recursive discovery and incremental rebuild behavior, while making the command surface more professional and easier to document for public use.
- Keep the image maintainable by relying on official upstream images where practical and minimizing custom runtime logic.
- Improve repository structure and documentation enough that the project can be published as a public utility.
- Automate image build, validation, and publication through GitHub Actions with `ghcr.io` as the canonical registry.

**Non-Goals:**
- Replacing PlantUML itself or adding a web service deployment model.
- Adding cloud sync, remote storage backends, or collaboration features.
- Solving every host filesystem edge case across every container runtime beyond documented Linux/macOS Docker usage.
- Expanding PDF generation unless it fits naturally into the same containerized toolchain.

## Decisions

### 1. Ship a purpose-built CLI container around official upstream tooling

The tool will be distributed as a Docker image whose entrypoint exposes stable commands such as render and watch. The image should use an official PlantUML base image if it provides a compatible CLI/runtime, or otherwise a minimal wrapper stage that copies the official PlantUML jar/runtime from upstream into a small final image.

Rationale:
- This keeps the public interface stable even if internal Make targets change.
- It reduces maintenance burden compared with manually downloading and versioning `plantuml.jar` inside the repo.
- It aligns with the user expectation of `docker run -v $(pwd):...` as the primary workflow.

Alternatives considered:
- Keep the Makefile as the primary interface and tell users to run `make` inside a generic container. Rejected because it exposes too much repo internals and feels less polished as a public tool.
- Build a fully custom image from a generic JRE base and download PlantUML during image build. Rejected because it adds maintenance and supply-chain surface without clear benefit if official assets are available.

### 2. Separate runtime configuration from repo-local paths

The container will operate on a configurable workspace mount path such as `/workspace`, with explicit input/output conventions documented in the CLI wrapper. The rendering logic should not depend on being run from the repository root; instead it should accept a target directory and discover `*.pu` files recursively within that mount.

Rationale:
- This makes the tool usable as a general-purpose public image, not just for this repository.
- It supports commands such as `docker run -v $(pwd):/workspace ... watch` cleanly.
- It avoids hard-coding host-specific paths and reduces confusion about where outputs are written.

Alternatives considered:
- Require users to mirror the repository layout exactly inside the container. Rejected because it is brittle and not suitable for public distribution.
- Always render in-place next to source files. Rejected because the existing project uses a dedicated `output/` tree and that pattern is easier to clean and reason about.

### 3. Handle permissions through runtime UID/GID mapping rather than post-processing

The container interface will support running as the invoking host user, typically via Docker `--user $(id -u):$(id -g)` in documented examples and helper commands. If needed, the entrypoint may also accept environment variables for UID/GID-aware setup, but the primary design favors Docker-native user mapping over in-container `chown`.

Rationale:
- Writing files as the calling user is simpler and safer than creating files as root and fixing ownership later.
- It works well for bind-mounted local workflows, which are the main target of this tool.
- It avoids privileged operations and reduces surprises in CI or on developer machines.

Alternatives considered:
- Run as root and `chown` output after every render. Rejected because it is slower, more error-prone, and awkward for long-running watch mode.
- Require a fixed non-root image user without mapping to the host. Rejected because host ownership mismatches would still occur.

### 4. Replace the ad hoc watch loop with a container-friendly wrapper

The current watch implementation loops forever around `find ... | entr -p make`. The new design will move this into a dedicated entrypoint or script that validates dependencies, performs an initial render, and then starts watch mode with clearer logging and robust restart behavior. The watch command should monitor `*.pu` changes recursively inside the mounted workspace and rerun the render command, keeping output semantics identical between one-shot and watch modes.

Rationale:
- A single container entrypoint is easier to document and support than exposing raw shell scripts.
- Consistent render logic between one-shot and watch mode reduces drift and bugs.
- It makes it easier to evolve from Make-centric internals toward a public-tool UX.

Alternatives considered:
- Keep `watch.sh` mostly unchanged and invoke it from Docker. Rejected because it preserves repo-specific assumptions and a rougher user experience.
- Use Docker Compose or a long-running sidecar model as the primary watch interface. Rejected because the requested UX is direct `docker run` usage.

### 5. Keep Make as an internal rendering optimization, not the public contract

The repository will use a `Makefile` exclusively for optimizing the internal PlantUML rendering loop (to avoid re-rendering unchanged `*.pu` files). It must **not** be used for building, testing, or publishing the container image itself. The public-facing workflow, docs, and release story will strictly center on cloud-native `docker run ghcr.io/make-plantuml:latest ...` commands.

Rationale:
- This aligns the project with cloud-native expectations where the container is the atomic unit of distribution.
- It prevents confusing abstractions (like wrappers or Makefiles building Docker images) and ensures users understand how to run the image in any environment (e.g. CI, local docker, kubernetes).
- The Makefile is retained solely to make the containerized rendering process fast and incremental.

Alternatives considered:
- Keep `make build` and `make test` for the container. Rejected because it hides standard Docker and CI/CD practices behind a legacy abstraction.
- Provide a `docker-run.sh` script for users. Rejected because it goes against the cloud-native pattern of directly running the published container image.

### 6. Publish images through GitHub Actions to GitHub Container Registry

The repository will define GitHub Actions workflows that build the image on pull requests for validation and publish tagged or main-branch images to GitHub Container Registry (`ghcr.io`) using GitHub-native authentication and metadata tagging.

Rationale:
- GitHub Actions keeps the release pipeline close to the source repository and easy for maintainers to audit.
- `ghcr.io` is the natural public registry for a GitHub-hosted tool and supports repository-linked package metadata.
- Separating validation builds from publish workflows reduces the risk of shipping broken images while still giving contributors quick feedback.

Alternatives considered:
- Build and push manually from local machines. Rejected because it is inconsistent, hard to audit, and unsuitable for public releases.
- Use a third-party registry or external CI first. Rejected because GitHub-hosted source plus GitHub-hosted registry is the simplest professional baseline for this project.

## Risks / Trade-offs

- [Official image constraints] -> The official PlantUML image may not include every helper dependency needed for watch mode, so a thin derivative image may still be required for `entr` and wrapper scripts.
- [Filesystem event behavior on mounted volumes] -> Recursive watching through Docker bind mounts can vary by platform; document supported environments and favor polling/restart-safe `entr` usage over more fragile assumptions.
- [Output path expectations] -> Users may want in-place output instead of `output/`; keep defaults predictable and consider configurable output roots in the final implementation.
- [Long-running container ergonomics] -> Watch mode needs clear logs and clean shutdown behavior; implement signal handling in the entrypoint and avoid nested shell loops that obscure failures.
- [Backward compatibility tension] -> Shifting emphasis from local jar downloads to Docker may confuse existing users; keep local contributor workflows available and document the transition clearly.
- [Registry publishing mistakes] -> Misconfigured workflow triggers or tags could publish incorrect images; gate publishing on explicit branches/tags and use deterministic metadata generation.
- [Supply-chain and permissions scope] -> Publishing to `ghcr.io` requires elevated workflow permissions; keep the workflow permissions minimal and use GitHub-maintained actions where possible.

## Migration Plan

1. Add container build assets, runtime scripts, and a documented CLI contract for render/watch operations.
2. Refactor repository automation so local Make targets can invoke the same underlying render logic used by the container.
3. Update documentation to present Docker usage as the recommended public interface, including mounted-volume examples with user mapping.
4. Validate generated file ownership and watch behavior on a bind-mounted local workspace.
5. Add GitHub Actions workflows for image validation and `ghcr.io` publication, including tagging and package metadata.
6. Preserve or intentionally deprecate older jar-download instructions with a clear compatibility note.

Rollback strategy: if the Dockerized workflow proves unreliable, the repository can continue to support the existing local Make-based path while the public image remains unpublished or marked experimental.

## Open Questions

- Should the public image support PDF generation from day one, or should the initial release focus strictly on `png`/`svg` rendering plus watch mode?
- Should outputs always go to `output/`, or should the image expose an option to render adjacent to source files for users integrating with other tooling?
- Which official upstream image provides the best balance of stability and extensibility for adding watch dependencies while keeping the image lean?
- Which branch and tag strategy should trigger `ghcr.io` publication for stable and edge images?
