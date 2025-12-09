PLANTUML_JAR := plantuml.jar
PLANTUML_URL := https://github.com/plantuml/plantuml/releases/download/v1.2024.3/plantuml-1.2024.3.jar

SRC_FILES := $(shell find . -name "*.pu")

define RENDER_RULE
SVG_TARGET := $(patsubst ./%.pu,output/%.svg,$(1))
PNG_TARGET := $(patsubst ./%.pu,output/%.png,$(1))

ALL_TARGETS += $$(SVG_TARGET) $$(PNG_TARGET)

$$(SVG_TARGET): $(1)
	@echo "Rendering $$< to $$@"
	@mkdir -p $$(dir $$@)
	@java -jar $(PLANTUML_JAR) -tsvg -pipe < $$< > $$@

$$(PNG_TARGET): $(1)
	@echo "Rendering $$< to $$@"
	@mkdir -p $$(dir $$@)
	@java -jar $(PLANTUML_JAR) -tpng -pipe < $$< > $$@
endef

$(foreach src,$(SRC_FILES),$(eval $(call RENDER_RULE,$(src))))

all: $(ALL_TARGETS)

download-plantuml:
	@echo "Downloading PlantUML..."
	@wget -O $(PLANTUML_JAR) $(PLANTUML_URL)

watch:
	@echo "Starting watch mode... Press Ctrl+C to stop."
	@./watch.sh

clean:
	@echo "Cleaning output directory..."
	@rm -rf output

.PHONY: all clean download-plantuml watch
