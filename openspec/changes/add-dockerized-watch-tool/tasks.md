## 1. Container Runtime Foundation

- [x] 1.1 Select and document the official PlantUML upstream image or asset source to use as the base for the public runtime.
- [x] 1.2 Add Docker build assets for a release-ready image that includes PlantUML plus watch-mode dependencies such as `entr`.
- [x] 1.3 Create a container entrypoint or CLI wrapper that exposes stable `render` and `watch` commands against a configurable workspace path.

## 2. Rendering And Watch Workflow

- [x] 2.1 Refactor the current render logic so one-shot rendering discovers `*.pu` files recursively in a target workspace and writes `svg`/`png` outputs to the documented output tree.
- [x] 2.2 Implement watch mode so it performs an initial render and then re-runs rendering when `*.pu` files change inside the mounted workspace.
- [x] 2.3 Add signal handling and clear logging for long-running watch mode so container shutdown and failures are easy to understand.

## 3. Host Compatibility And Maintainer Ergonomics

- [x] 3.1 Design the runtime interface and examples around Docker user mapping so generated files in bind mounts keep host-compatible ownership.
- [x] 3.2 Update repository to strictly use `Makefile` for PlantUML incremental rendering only, avoiding it for building/testing the container itself.
- [x] 3.3 Ensure cloud-native commands like `docker run ghcr.io/<owner>/make-plantuml:latest ...` replace legacy helper scripts (`docker-run.sh` or `Makefile` wrapper targets).

## 4. Release Polish And Verification

- [x] 4.1 Rewrite the README and related docs to present the published `ghcr.io` Docker image as the primary public interface (e.g. `docker run ghcr.io/make-plantuml:latest watch`).
- [x] 4.2 Add troubleshooting and usage notes covering output paths, bind mounts, permissions, and supported environments.
- [x] 4.3 Validate the image by building it and exercising both render and watch flows using pure docker commands against a mounted sample workspace.

## 5. CI/CD And Registry Publishing

- [x] 5.1 Add a GitHub Actions workflow that builds the Docker image for pull requests and other validation triggers.
- [x] 5.2 Add a GitHub Actions publish workflow that authenticates with GitHub Container Registry and pushes the image to `ghcr.io` with documented tags and OCI metadata.
- [x] 5.3 Configure workflow permissions, package naming, and trigger rules so only intended branches or tags can publish public images.
## 6. Post-Release Fixes (SELinux, Podman, and Flexibility)

- [x] 6.1 Refactor `Makefile` and `plantuml-tool.sh` to output rendered diagrams alongside source files by default instead of enforcing an `output/` directory, resolving volume mount permission blockers.
- [x] 6.2 Update `README.md` troubleshooting, examples, and documentation to include specific guidance for running under Podman vs. Docker, including rootless User Namespaces and SELinux `:z` mount requirements.
- [x] 6.3 Update the build toolchain (`Makefile` and `plantuml-tool.sh`) to support `.puml` file extensions in addition to `.pu`.
- [x] 6.4 Fix the one-shot `render` command so it forces a complete re-render (`make -B`) instead of skipping existing output files.
- [x] 6.5 Add `-o` / `--output` flag parsing to `plantuml-tool.sh` so users can specify the output directory natively via arguments.
