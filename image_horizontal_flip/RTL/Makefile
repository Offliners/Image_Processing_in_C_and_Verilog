# TOOL INPUT
DESIGN_NAME = HORIZONTAL_FLIP
DESIGN      = TESTBENCH.v
TESTBENCH   = TESTBENCH.v
COUTPUT     = $(DESIGN_NAME).out
TBOUTPUT    = $(DESIGN_NAME).vcd
OUTPUT_BMP  = output.bmp

# TOOLS
COMPILER = iverilog
SIMULATOR = vvp
VIEWER = gtkwave

# TOOL OPTIONS
COFLAGS = -o
SFLAGS = -i

# MAKE DIRECTIVES
.PHONY : check simulate displays
check: $(DESIGN)
	@echo "Check $(DESIGN)"
	@$(COMPILER) $(COFLAGS) $(COUTPUT) $(DESIGN)

simulate: $(TESTBENCH)
	@echo "Simulate $(COUTPUT)"
	@$(COMPILER) $(COFLAGS) $(COUTPUT) $(TESTBENCH)
	@$(SIMULATOR) $(SFLAGS) $(COUTPUT)

wave: $(TBOUTPUT)
	@echo "Display $(TBOUTPUT)"
	@$(VIEWER) $(TBOUTPUT) &

# CLEAN THE FILE
.PHONY : clean
clean:
	@echo "Clean $(COUTPUT) $(TBOUTPUT) $(OUTPUT_BMP)"
	@rm -rf $(COUTPUT) $(TBOUTPUT) $(OUTPUT_BMP)

.PHONY : help
help:
	@echo "make simulate - compile and run testbench"
