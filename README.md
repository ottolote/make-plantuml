# PlantUML Watcher

`make-plantuml` is a container-first PlantUML renderer for folders full of `*.pu` and `*.puml` files. It renders `svg` and `png` outputs alongside the source files by default, can stay running in watch mode, and avoids the usual host setup pain around Java, PlantUML, and file permissions.

The runtime is built on top of the official `plantuml/plantuml` image and adds a thin wrapper around a bundled Makefile for recursive rendering, watch mode, and container-friendly defaults.

## Usage

Generated files are saved alongside the source files by default. Depending on your container engine, you will need slightly different arguments to ensure output files are owned by your user and not `root`.

### Running with Docker

When using standard Docker, you should pass your user IDs to prevent the container from creating `root`-owned files on your host machine.

Run a one-shot render against the current directory:

```sh
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$(pwd):/workspace" \
  ghcr.io/ottolote/make-plantuml:latest render
```

Run continuous watch mode:

```sh
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  -v "$(pwd):/workspace" \
  ghcr.io/ottolote/make-plantuml:latest watch
```

### Running with Podman

When using rootless Podman, container `root` is automatically mapped to your host user. Using Docker's `--user` flag will cause permission denied errors due to subordinate UID mapping. You have two options:

**Option 1: Rely on rootless mapping (Recommended)**
Omit the `--user` flag. The container runs as its internal root, which maps safely to your standard user on the host. If your directory is on an SELinux enforcing host, ensure you append `:z` to the volume mount:

```sh
podman run --rm \
  -v "$(pwd):/workspace:z" \
  ghcr.io/ottolote/make-plantuml:latest render
```

**Option 2: Use keep-id**
If you prefer explicit user mapping, use the `--userns=keep-id` flag:

```sh
podman run --rm -it \
  --userns=keep-id \
  -v "$(pwd):/workspace:z" \
  ghcr.io/ottolote/make-plantuml:latest watch
```

## Configuration

Defaults:

- Workspace inside the container: `/workspace`
- Output directory inside the mounted workspace: (empty, renders alongside `.pu` and `.puml` files)
- Rendered formats: `svg`, `png`

You can override runtime settings with environment variables:

```sh
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e OUTPUT_DIR=artifacts \
  -e FORMATS=svg,pdf \
  -v "$(pwd):/workspace" \
  ghcr.io/ottolote/make-plantuml:latest render
```

Supported environment variables:

- `WORKSPACE`: mounted workspace path inside the container, defaults to `/workspace`
- `OUTPUT_DIR`: optional output root inside the workspace. If empty (default), files render alongside source files. You can also set this by passing `-o <dir>` or `--output <dir>` as an argument.
- `FORMATS`: comma-separated output formats, defaults to `svg,png` (supports any format `-t<format>` supported by PlantUML, like `pdf`, `txt`, `epsi`, etc.)
- `POLL_INTERVAL`: wait time in seconds when no source files exist yet, defaults to `2`

## Output Layout

For a source file like:

```text
activity-diagrams/example.pu
```

The tool writes by default:

```text
activity-diagrams/example.svg
activity-diagrams/example.png
```

## Architecture Note

The repository contains an internal `Makefile`. This `Makefile` is strictly used **inside the container** as an optimization to prevent re-rendering unchanged files. It is explicitly **not** used to build, test, or publish the container itself. All workflows rely on standard cloud-native tools (`docker run`, `docker build`) rather than legacy wrapper scripts.

## Maintainer Workflow

To develop the tool locally, you can build the image directly and run it using pure Docker commands:

- `docker build -t local/make-plantuml:dev .`: build the local development image
- `docker run --rm -v "$(pwd):/workspace" local/make-plantuml:dev render`: test your local changes by rendering the repository's diagrams
- `docker run --rm -it -v "$(pwd):/workspace" local/make-plantuml:dev watch`: test watch mode using your local build
- `docker run --rm -it -v "$(pwd):/workspace" local/make-plantuml:dev bash`: drop into a shell inside the container

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

- `root`-owned output files (Docker): run the container with `--user "$(id -u):$(id -g)"`
- Permission denied writing output files (Podman): ensure you are not using `--user` as the sub-uid mapping will fail. Use `--userns=keep-id` instead or drop the user flag.
- Permission denied on mounted folder (SELinux): ensure your volume mount has the `:z` suffix (e.g. `-v "$(pwd):/workspace:z"`).
- No live updates on mounted folders: watch mode relies on `entr`; if your host delays filesystem events, retry on Linux or expect slower feedback on some desktop setups
- No diagrams rendered: make sure your mounted folder contains `*.pu` or `*.puml` files outside the configured output directory
- Need a different output folder: set `OUTPUT_DIR=<name>` at runtime.

## Official Runtime Source

The image is based on the official `plantuml/plantuml:latest` container and adds only the small amount of tooling needed for recursive rendering, watch mode, and GitHub-ready distribution.