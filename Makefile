PLANTUML_JAR := plantuml.jar
PLANTUML_URL := https://github.com/plantuml/plantuml/releases/download/v1.2024.3/plantuml-1.2024.3.jar

# Find all .pu files recursively
SRC_FILES_RAW := $(shell find . -name "*.pu")

# Define a function to transform raw source file path to SVG target path
define to_svg_target
$(patsubst ./%.pu,output/%.svg,$1)
endef

# Define a function to transform raw source file path to PNG target path
define to_png_target
$(patsubst ./%.pu,output/%.png,$1)
endef

# Build the list of all SVG and PNG target files
ALL_SVG_TARGETS := $(foreach src,$(SRC_FILES_RAW),$(call to_svg_target,$(src)))
ALL_PNG_TARGETS := $(foreach src,$(SRC_FILES_RAW),$(call to_png_target,$(src)))
ALL_TARGETS := $(ALL_SVG_TARGETS) $(ALL_PNG_TARGETS)

.PHONY: all
all: $(ALL_TARGETS)

# Define a rule for each SVG target
output/%.svg: ./%.pu
	@echo "Rendering '$<' to '$@'"
	@mkdir -p "$(dir $@)"
	@java -jar $(PLANTUML_JAR) -tsvg -pipe < "$<" > "$@"

# Define a rule for each PNG target
output/%.png: ./%.pu
	@echo "Rendering '$<' to '$@'"
	@mkdir -p "$(dir $@)"
	@java -jar $(PLANTUML_JAR) -tpng -pipe < "$<" > "$@"

download-plantuml:
	@echo "Downloading PlantUML..."
	@wget -O $(PLANTUML_JAR) $(PLANTUML_URL)

watch:
	@echo "Starting watch mode... Press Ctrl+C to stop."
	@./watch.sh

clean:
	@echo "Cleaning output directory..."
	@rm -rf output

.PHONY: clean download-plantuml watch