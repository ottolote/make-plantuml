# --- Variables ---
PLANTUML_JAR := plantuml.jar
PLANTUML_URL := https://github.com/plantuml/plantuml/releases/download/v1.2024.3/plantuml-1.2024.3.jar

# Find all .pu files
SRC_FILES := $(shell find . -name "*.pu")

# --- Rule Generation ---
define RENDER_RULE
# For a given source file (e.g., ./test/nisse.pu), define its targets and rules.
SVG_TARGET := $(patsubst ./%.pu,output/%.svg,$(1))
PNG_TARGET := $(patsubst ./%.pu,output/%.png,$(1))

ALL_TARGETS += $$(SVG_TARGET) $$(PNG_TARGET)

# Rule for the SVG file. It only depends on the source file.
# If plantuml.jar is missing, the 'java -jar' command itself will fail.
$$(SVG_TARGET): $(1)
	@echo "Rendering $$< to $$@"
	@mkdir -p $$(dir $$@)
	@java -jar $(PLANTUML_JAR) -tsvg -pipe < $$< > $$@

# Rule for the PNG file
$$(PNG_TARGET): $(1)
	@echo "Rendering $$< to $$@"
	@mkdir -p $$(dir $$@)
	@java -jar $(PLANTUML_JAR) -tpng -pipe < $$< > $$@

endef

$(foreach src,$(SRC_FILES),$(eval $(call RENDER_RULE,$(src))))


# --- Main Targets ---
all: $(ALL_TARGETS)

download-plantuml:
	@echo "Downloading PlantUML..."
	@wget -O $(PLANTUML_JAR) $(PLANTUML_URL)

watch:
	@echo "Starting watch mode... Press Ctrl+C to stop."
	@./watch.sh


# --- Utility Targets ---
clean:
	@echo "Cleaning output directory..."
	@rm -rf output

.PHONY: all clean download-plantuml watch