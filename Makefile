# --- Variables ---
PLANTUML_JAR := plantuml.jar
PLANTUML_URL := https://github.com/plantuml/plantuml/releases/download/v1.2024.3/plantuml-1.2024.3.jar

# Find all .pu files, removing the leading ./ 
SRC_FILES := $(patsubst ./%,%,$(shell find . -name "*.pu"))

# Generate the list of all target files we want to create
TARGET_FILES := $(patsubst %.pu,output/%.svg,$(SRC_FILES)) \
                $(patsubst %.pu,output/%.png,$(SRC_FILES))


# --- Main Targets ---

# The default 'all' target depends on all the generated targets, and on the JAR file.
all: $(PLANTUML_JAR) $(TARGET_FILES)

# Rule to download plantuml.jar
$(PLANTUML_JAR):
	@echo "Downloading PlantUML..."
	@wget -O $(PLANTUML_JAR) $(PLANTUML_URL)

install: $(PLANTUML_JAR)


# --- Pattern Rules ---

# Rule for creating an SVG file from a .pu file
output/%.svg: %.pu $(PLANTUML_JAR)
	@echo "Rendering $< to $@"
	@mkdir -p $(dir $@)
	@java -jar $(PLANTUML_JAR) -tsvg -pipe < $< > $@

# Rule for creating a PNG file from a .pu file
output/%.png: %.pu $(PLANTUML_JAR)
	@echo "Rendering $< to $@"
	@mkdir -p $(dir $@)
	@java -jar $(PLANTUML_JAR) -tpng -pipe < $< > $@


# --- Utility Targets ---
clean:
	@echo "Cleaning output directory and downloaded JAR..."
	@rm -rf output $(PLANTUML_JAR)

# Mark targets that are not actual files
.PHONY: all clean install