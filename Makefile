PLANTUML_JAR ?= /opt/plantuml.jar
OUTPUT_DIR ?= output
FORMATS ?= svg,png

# Find all .pu files recursively, excluding OUTPUT_DIR
SRC_FILES_RAW := $(shell find . -path "./$(OUTPUT_DIR)" -prune -o -name "*.pu" -print)

# Parse formats
COMMA := ,
FORMAT_LIST := $(subst $(COMMA), ,$(FORMATS))

# Define functions to transform raw source file path to target paths
define to_target
$(patsubst ./%.pu,$(OUTPUT_DIR)/%.$2,$1)
endef

# Build the list of all target files dynamically based on FORMATS
ALL_TARGETS := $(foreach fmt,$(FORMAT_LIST),$(foreach src,$(SRC_FILES_RAW),$(call to_target,$(src),$(fmt))))

.PHONY: all
all: $(ALL_TARGETS)

# Generic rule for any format supported by plantuml (-tfmt)
$(OUTPUT_DIR)/%.svg: ./%.pu
	@echo "Rendering '$<' to '$@'"
	@mkdir -p "$(dir $@)"
	@java -jar $(PLANTUML_JAR) -tsvg -pipe < "$<" > "$@"

$(OUTPUT_DIR)/%.png: ./%.pu
	@echo "Rendering '$<' to '$@'"
	@mkdir -p "$(dir $@)"
	@java -jar $(PLANTUML_JAR) -tpng -pipe < "$<" > "$@"

$(OUTPUT_DIR)/%.pdf: ./%.pu
	@echo "Rendering '$<' to '$@'"
	@mkdir -p "$(dir $@)"
	@java -jar $(PLANTUML_JAR) -tpdf -pipe < "$<" > "$@"

ALL_SVG_TARGETS := $(foreach src,$(SRC_FILES_RAW),$(call to_target,$(src),svg))

.PHONY: pdf-typst
pdf-typst: $(ALL_SVG_TARGETS)
	@echo "Creating diagrams.pdf with typst..."
	@if ! command -v typst &> /dev/null; then \
		echo "Error: 'typst' is not installed. Please install it to continue."; \
		exit 1; \
	fi
	@echo "#set page(width: auto, height: auto, margin: 1cm)" > diagrams.typ
	@for svg in $(ALL_SVG_TARGETS); do \
		echo "#figure(image(\"$$svg\"))" >> diagrams.typ; \
	done
	@typst compile diagrams.typ
	@rm diagrams.typ
	@echo "Successfully created diagrams.pdf"

download-plantuml:
	@echo "Downloading PlantUML..."
	@if [ "$(PLANTUML_JAR)" != "/opt/plantuml.jar" ]; then \
		wget -O $(PLANTUML_JAR) https://github.com/plantuml/plantuml/releases/download/v1.2024.3/plantuml-1.2024.3.jar; \
	else \
		echo "Inside container. No need to download."; \
	fi

clean:
	@echo "Cleaning output directory..."
	@rm -rf $(OUTPUT_DIR) diagrams.pdf

.PHONY: clean download-plantuml