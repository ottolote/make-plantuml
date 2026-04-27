# PlantUML Watcher

`make-plantuml` is a Docker-first PlantUML renderer for folders full of `*.pu` files. It renders `svg` and `png` outputs into an `output/` tree, can stay running in watch mode, and avoids the usual host setup pain around Java, PlantUML, and file permissions.

The runtime is built on top of the official `plantuml/plantuml` image and adds a thin wrapper around a bundled Makefile for recursive rendering, watch mode, and container-friendly defaults.

## Quick Start

Render the current directory:

```sh
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$(pwd):/workspace" \
  ghcr.io/<owner>/make-plantuml:latest render
```

Watch the current directory for changes:

```sh
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  -v "$(pwd):/workspace" \
  ghcr.io/<owner>/make-plantuml:latest watch
```

Generated files land under `output/`, preserving the source folder structure.

## Docker Usage

Run a one-shot render against any mounted folder:

```sh
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$(pwd):/workspace" \
  ghcr.io/<owner>/make-plantuml:latest render
```

Run continuous watch mode:

```sh
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  -v "$(pwd):/workspace" \
  ghcr.io/<owner>/make-plantuml:latest watch
```

Defaults:

- Workspace inside the container: `/workspace`
- Output directory inside the mounted workspace: `output/`
- Rendered formats: `svg`, `png`

You can override runtime settings with environment variables:

```sh
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e OUTPUT_DIR=artifacts \
  -e FORMATS=svg,pdf \
  -v "$(pwd):/workspace" \
  ghcr.io/<owner>/make-plantuml:latest render
```

Supported environment variables:

- `WORKSPACE`: mounted workspace path inside the container, defaults to `/workspace`
- `OUTPUT_DIR`: output root inside the workspace, defaults to `output`
- `FORMATS`: comma-separated output formats, defaults to `svg,png` (supports any format `-t<format>` supported by PlantUML, like `pdf`, `txt`, `epsi`, etc.)
- `POLL_INTERVAL`: wait time in seconds when no `*.pu` files exist yet, defaults to `2`

## Architecture Note

The repository contains an internal `Makefile`. This `Makefile` is strictly used **inside the container** as an optimization to prevent re-rendering unchanged `*.pu` files. It is explicitly **not** used to build, test, or publish the container itself. All workflows rely on standard cloud-native tools (`docker run`, `docker build`) rather than legacy wrapper scripts.

## Maintainer Workflow

To develop the tool locally, you can build the image directly and run it using pure Docker commands:

- `docker build -t local/make-plantuml:dev .`: build the local development image
- `docker run --rm -v "$(pwd):/workspace" local/make-plantuml:dev render`: test your local changes by rendering the repository's diagrams
- `docker run --rm -it -v "$(pwd):/workspace" local/make-plantuml:dev watch`: test watch mode using your local build
- `docker run --rm -it -v "$(pwd):/workspace" local/make-plantuml:dev bash`: drop into a shell inside the container

## Output Layout

For a source file like:

```text
activity-diagrams/example.pu
```

The tool writes:

```text
output/activity-diagrams/example.svg
output/activity-diagrams/example.png
```

## CI/CD And Releases

GitHub Actions handles both validation and publication:

- Pull requests and `main` builds run a Docker build plus a render smoke test
- Pushes to `main` publish a `latest` image and a commit-specific `sha-*` tag to `ghcr.io`
- Version tags matching `v*` publish release images to `ghcr.io` and also update `latest`

Expected package location:

```text
ghcr.io/<owner>/make-plantuml
```

## Troubleshooting

- `root`-owned output files: run the container with `--user "$(id -u):$(id -g)"`
- No live updates on mounted folders: watch mode relies on `entr`; if your Docker host delays filesystem events, retry on Linux or expect slower feedback on some desktop setups
- No diagrams rendered: make sure your mounted folder contains `*.pu` files outside the configured output directory
- Need a different output folder: set `OUTPUT_DIR=<name>` at runtime

## Official Runtime Source

The image is based on the official `plantuml/plantuml:latest` container and adds only the small amount of tooling needed for recursive rendering, watch mode, and GitHub-ready distribution.
