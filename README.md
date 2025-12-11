# Declarative PlantUML Tooling

This repository provides simple tooling to work with [PlantUML](httpss://plantuml.com/) diagrams in a declarative way. It automatically discovers all `.pu` files in the repository and renders them to `svg` and `png` formats in the `output/` directory.

## Usage

### Prerequisites

*   [Java](httpss://www.java.com/en/download/): Required for PlantUML.
*   [GNU Make](httpss://www.gnu.org/software/make/): The build automation tool used.

#### Tool-specific Dependencies

*   **make watch**: Requires [`entr`](http://eradman.com/entrproject/).
    *   On macOS: `brew install entr`
    *   On Linux (Debian/Ubuntu): `sudo apt-get install entr`
*   **make pdf**: Requires [`typst`](https://typst.app/get-started/).
    *   Installation instructions can be found on the Typst website. A common method for Linux is to download the pre-compiled binary and move it to `/usr/local/bin`.
    *   On macOS (with Homebrew): `brew install typst`
    *   On Linux (Debian/Ubuntu, if not available via apt):
        ```bash
        wget -qO typst.tar.xz https://github.com/typst/typst/releases/latest/download/typst-x86_64-unknown-linux-musl.tar.xz
        tar -xf typst.tar.xz
        sudo mv typst-x86_64-unknown-linux-musl/typst /usr/local/bin/
        rm typst.tar.xz
        rm -r typst-x86_64-unknown-linux-musl
        ```

### PlantUML JAR

Before rendering any diagrams, you must download the PlantUML JAR file:

```sh
make download-plantuml
```

This command only needs to be run once.

### Rendering Diagrams

To render all `.pu` diagrams to `.svg` and `.png` formats:

```sh
make
```

This will generate `.svg` and `.png` files for all `.pu` files in the `output/` directory, preserving the directory structure.

### Generating PDF Diagrams

To generate a single PDF file containing all diagrams:

```sh
make pdf
```

This will first render all `.pu` files to `.svg` and then use `typst` to compile them into `diagrams.pdf` in the root directory of the project.

### Watching for Changes

To automatically re-render diagrams when a `.pu` file is modified:

```sh
make watch
```

This requires `entr` to be installed.

Note: `make` will only re-render the `.pu` file that has been modified, not all diagrams.

### Cleaning Up

To remove all generated output (including `diagrams.pdf`):

```sh
make clean
```