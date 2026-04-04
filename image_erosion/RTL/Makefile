# Generated layout aligned with NTU_DSP_in_VLSI_writeup/HW01/Makefile
.PHONY: syn syn_dv read_dv_rtl read_ddc vcs_rtl vcs_gate irun_rtl irun_gate xrun_rtl xrun_gate \
	nWave verdi_rtl verdi_gate clean help ivl_rtl gtk_wave

######################################
# Icarus Verilog (original flow)
######################################
DESIGN_NAME = IMAGE_EROSION
DESIGN      = TESTBENCH.v
TESTBENCH   = TESTBENCH.v
COUTPUT     = $(DESIGN_NAME).out
TBOUTPUT    = $(DESIGN_NAME).vcd
OUTPUT_BMP  = output.bmp

COMPILER  = iverilog
IVERILOG_FLAGS = -g2012
SIMULATOR = vvp
VIEWER    = gtkwave
COFLAGS   = -o
SFLAGS    = -i

######################################
# VCS / irun / DC / Verdi
######################################
top_design=$(DESIGN_NAME)
source_file="filelist.f"
output_file="simv"
log_file="vcs.log"
syn_tcl="syn.tcl"
syn_log="syn.log"

num_CPU_cores=4
TIMESCALE=-timescale=1ns/1fs
TIMESCALE1=-timescale 1ns/1fs
VERDI=/usr/cad/synopsys/verdi/
DW_SIM=/usr/cad/synopsys/synthesis/cur/dw/sim_ver/
TSMC013_SIM=~/iclabTA01/TSMC_013/Verilog/tsmc13_neg.v

# ============== VCS ==================
VCS_RTL_SIM = vcs ${TIMESCALE} \
    -j${num_CPU_cores} \
    -sverilog \
    +v2k \
    -full64 \
    -Mupdate \
    -R \
    -debug_access+all \
    -y ${DW_SIM} \
    +libext+.v \
    -f ${source_file} \
    -o ${output_file} \
    -l ${log_file} \
    -P ${VERDI}/share/PLI/VCS/linux64/novas.tab \
       ${VERDI}/share/PLI/VCS/linux64/pli.a \
    +define+RTL \
    +notimingchecks

VCS_GATE_SIM = vcs ${TIMESCALE} \
    -j${num_CPU_cores} \
    -sverilog \
    +v2k \
    -full64 \
    -Mupdate \
    -R \
    -debug_access+all \
    -f ${source_file} \
    -o ${output_file} \
    -l ${log_file} \
    -P ${VERDI}/share/PLI/VCS/linux64/novas.tab \
       ${VERDI}/share/PLI/VCS/linux64/pli.a \
    -v ${TSMC013_SIM} \
    +define+GATE \
    +neg_tchk

# ============== irun =================
IRUN_RTL_SIM = irun -f ${source_file} \
    -incdir ${DW_SIM} \
    -loadpli1 debpli:novas_pli_boot \
    -debug \
    -notimingchecks \
    -define RTL

IRUN_GATE_SIM = irun -f ${source_file} \
    -override_precision \
    ${TIMESCALE1} \
    -sdf_precision 1fs \
    -v ${TSMC013_SIM} \
    -loadpli1 debpli:novas_pli_boot \
    -debug \
    -define GATE

# ============== xrun =================
XRUN_RTL_SIM = xrun -f ${source_file} \
    -mcl ${num_CPU_cores} \
    -incdir ${DW_SIM} \
    -loadpli1 debpli:novas_pli_boot \
    -debug \
    -notimingchecks \
    -define RTL

XRUN_GATE_SIM = xrun -f ${source_file} \
    -mcl ${num_CPU_cores} \
    -override_precision \
    ${TIMESCALE1} \
    -sdf_precision 1fs \
    -v ${TSMC013_SIM} \
    -loadpli1 debpli:novas_pli_boot \
    -debug \
    -define GATE

# ============= verdi / nWave =================
nWave_ON = nWave -ssf *.fsdb

VERDI_RTL_ON = verdi -ssf *.fsdb \
    -sv \
    -f ${source_file} \
    -nologo \
    +define+RTL \
    +v2k \
    -autoalias

VERDI_GATE_ON = verdi -ssf *.fsdb \
    -sv \
    -f ${source_file} \
    -nologo \
    +define+GATE \
    +v2k \
    -autoalias

# ========== Design Compiler ==========
DC_shell = dc_shell -f ${syn_tcl} \
    -x "set_host_options -max_cores ${num_CPU_cores}" \
    -output_log_file ${syn_log}

DC_shell_gui = dc_shell -f ${syn_tcl} \
    -x "set_host_options -max_cores ${num_CPU_cores}" \
    -output_log_file ${syn_log} \
    -gui

Read_DC_shell_gui = dc_shell -x 'read_verilog ${top_design}.v' -gui
Read_DDC_shell_gui = dc_shell -x "read_ddc ${top_design}_SYN.ddc" -gui

# ============= clean =================
clean_vcs = rm -rf *.fsdb ./csrc *.log simv* *.sdf.X *.key
clean_irun = rm -rf *.fsdb *.sdf.X ./INCA_libs *.history *.log
clean_xrun = rm -rf *.fsdb *.sdf.X ./xcelium.d *.history *.log
clean_verdi = rm -rf ./nWaveLog ./verdiLog *.conf *.rc *.log *.fsdb.*
clean_syn = rm -rf ./Netlist/*.* ./Report/*.* *.log alib* *.svf dwsvf* *.ddc *.pvl *.syn *.mr *_SYN.v *_SYN.ddc *_SYN.sdf *_SYN.sdc

# ============= Icarus clean ==========
clean_ivl:
	@echo "Clean $(COUTPUT) $(TBOUTPUT) $(OUTPUT_BMP) temp_bmp.txt"
	@rm -rf $(COUTPUT) $(TBOUTPUT) $(OUTPUT_BMP) temp_bmp.txt


ivl_rtl: $(TESTBENCH)
	@echo "ivl_rtl $(COUTPUT)"
	@$(COMPILER) $(IVERILOG_FLAGS) $(COFLAGS) $(COUTPUT) $(TESTBENCH)
	@$(SIMULATOR) $(SFLAGS) $(COUTPUT)

gtk_wave: $(TBOUTPUT)
	@echo "gtkwave $(TBOUTPUT)"
	@$(VIEWER) $(TBOUTPUT) &

vcs_rtl:
	${VCS_RTL_SIM}

vcs_gate:
	${VCS_GATE_SIM}

irun_rtl:
	${IRUN_RTL_SIM}

irun_gate:
	${IRUN_GATE_SIM}

xrun_rtl:
	${XRUN_RTL_SIM}

xrun_gate:
	${XRUN_GATE_SIM}

syn:
	mkdir -p ./Report/
	${DC_shell}

syn_dv:
	${DC_shell_gui}

read_dv_rtl:
	${Read_DC_shell_gui}

read_ddc:
	${Read_DDC_shell_gui}

nWave:
	${nWave_ON}

verdi_rtl:
	${VERDI_RTL_ON}

verdi_gate:
	${VERDI_GATE_ON}

clean: clean_ivl
	${clean_vcs}
	${clean_irun}
	${clean_xrun}
	${clean_verdi}
	${clean_syn}

help:
	@echo "Icarus:  make ivl_rtl | gtk_wave"
	@echo "VCS:     make vcs_rtl | vcs_gate"
	@echo "irun:    make irun_rtl | irun_gate"
	@echo "xrun:    make xrun_rtl | xrun_gate"
	@echo "DC:      make syn | syn_dv | read_dv_rtl | read_ddc"
	@echo "Debug:   make nWave | verdi_rtl | verdi_gate"
	@echo "clean:   make clean"
