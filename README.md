# Declarative PlantUML Tooling

This repository provides simple tooling to work with [PlantUML](httpss://plantuml.com/) diagrams in a declarative way. It automatically discovers all `.pu` files in the repository and renders them to `svg` and `png` formats in the `output/` directory.

## Usage

### Prerequisites

*   [Java](httpss://www.java.com/en/download/)
*   [GNU Make](httpss://www.gnu.org/software/make/)

### PlantUML JAR

Before rendering any diagrams, you must download the PlantUML JAR file:

```sh
make download-plantuml
```

This command only needs to be run once.

### Rendering Diagrams

To render all `.pu` diagrams:

```sh
make
```

This will generate `.svg` and `.png` files for all `.pu` files in the `output/` directory, preserving the directory structure.

### Watching for Changes

To automatically re-render diagrams when a `.pu` file is modified:

```sh
make watch
```

This requires `entr` to be installed.

Note: `make` will only re-render the `.pu` file that has been modified, not all diagrams.

### Cleaning Up

To remove all generated output:

```sh
make clean
```