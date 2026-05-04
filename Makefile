PLANTUML_JAR ?= /opt/plantuml.jar
OUTPUT_DIR ?=
FORMATS ?= svg,png

# Find all .pu and .puml files recursively
ifeq ($(OUTPUT_DIR),)
SRC_FILES_RAW := $(shell find . -type f \( -name "*.pu" -o -name "*.puml" \) -print)
else
SRC_FILES_RAW := $(shell find . -path "./$(OUTPUT_DIR)" -prune -o -type f \( -name "*.pu" -o -name "*.puml" \) -print)
endif

# Parse formats
COMMA := ,
FORMAT_LIST := $(subst $(COMMA), ,$(FORMATS))

# Define functions to transform raw source file path to target paths
define to_target
$(if $(OUTPUT_DIR),$(OUTPUT_DIR)/$(patsubst ./%,%,$(basename $1)).$2,$(basename $1).$2)
endef

# Build the list of all target files dynamically based on FORMATS
ALL_TARGETS := $(foreach fmt,$(FORMAT_LIST),$(foreach src,$(SRC_FILES_RAW),$(call to_target,$(src),$(fmt))))

.PHONY: all
all: $(ALL_TARGETS)

ifeq ($(OUTPUT_DIR),)

%.svg: %.pu
	@echo "Rendering '$<' to '$@'"
	@java -jar $(PLANTUML_JAR) -tsvg -pipe < "$<" > "$@"

%.svg: %.puml
	@echo "Rendering '$<' to '$@'"
	@java -jar $(PLANTUML_JAR) -tsvg -pipe < "$<" > "$@"

%.png: %.pu
	@echo "Rendering '$<' to '$@'"
	@java -jar $(PLANTUML_JAR) -tpng -pipe < "$<" > "$@"

%.png: %.puml
	@echo "Rendering '$<' to '$@'"
	@java -jar $(PLANTUML_JAR) -tpng -pipe < "$<" > "$@"

%.pdf: %.pu
	@echo "Rendering '$<' to '$@'"
	@java -jar $(PLANTUML_JAR) -tpdf -pipe < "$<" > "$@"

%.pdf: %.puml
	@echo "Rendering '$<' to '$@'"
	@java -jar $(PLANTUML_JAR) -tpdf -pipe < "$<" > "$@"

else

$(OUTPUT_DIR)/%.svg: ./%.pu
	@echo "Rendering '$<' to '$@'"
	@mkdir -p "$(dir $@)"
	@java -jar $(PLANTUML_JAR) -tsvg -pipe < "$<" > "$@"

$(OUTPUT_DIR)/%.svg: ./%.puml
	@echo "Rendering '$<' to '$@'"
	@mkdir -p "$(dir $@)"
	@java -jar $(PLANTUML_JAR) -tsvg -pipe < "$<" > "$@"

$(OUTPUT_DIR)/%.png: ./%.pu
	@echo "Rendering '$<' to '$@'"
	@mkdir -p "$(dir $@)"
	@java -jar $(PLANTUML_JAR) -tpng -pipe < "$<" > "$@"

$(OUTPUT_DIR)/%.png: ./%.puml
	@echo "Rendering '$<' to '$@'"
	@mkdir -p "$(dir $@)"
	@java -jar $(PLANTUML_JAR) -tpng -pipe < "$<" > "$@"

$(OUTPUT_DIR)/%.pdf: ./%.pu
	@echo "Rendering '$<' to '$@'"
	@mkdir -p "$(dir $@)"
	@java -jar $(PLANTUML_JAR) -tpdf -pipe < "$<" > "$@"

$(OUTPUT_DIR)/%.pdf: ./%.puml
	@echo "Rendering '$<' to '$@'"
	@mkdir -p "$(dir $@)"
	@java -jar $(PLANTUML_JAR) -tpdf -pipe < "$<" > "$@"

endif

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
	@echo "Cleaning outputs..."
	@if [ -n "$(OUTPUT_DIR)" ]; then \
		rm -rf $(OUTPUT_DIR); \
	else \
		rm -f $(ALL_TARGETS); \
	fi
	@rm -f diagrams.pdf

.PHONY: clean download-plantuml