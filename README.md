# 4-bit Array Multiplier: RTL to GDSII 


## Team

| Name | Roll number |
|---|---|
| Swarnava Pal | 2023112008 |
| Divesh Kumar | 2024102079 |


## Commands run, in order


### Part A: RTL and verification

```bash
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
gtkwave mult.vcd
```

### Part B: Yosys synthesis

```bash
yosys -c synth/synth.tcl
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
  tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls
```

### Part C: OpenSTA

Run 1 used `set T 10.0` in `sta/sta.tcl`; run 2 used `set T 2.79`.

```bash
sta -no_init -exit sta/sta.tcl     # T = 10.0
sta -no_init -exit sta/sta.tcl     # T = 2.79 
```

### Part D: LibreLane place and route

`CLOCK_PERIOD` was set to 1.2 x Tmin = 3.348 ns, rounded up to 3.5 ns, then
raised by 0.5 ns after every failed run.

```bash
cd pnr
librelane config.json                      # repeated for each CLOCK_PERIOD below
cp runs/RUN_2026-10-26_05-23-57/final/metrics.json .
cp runs/RUN_2026-10-26_05-23-57/final/gds/mult_array.gds .
klayout mult_array.gds
cd ..
```

#### Attempt log

Every attempt finished with 0 DRC, 0 LVS and 0 antenna errors. The failures
were all setup-timing violations at the slow sign-off corner
(`max_ss_100C_1v60`). The `runs/` folder is not committed.

| Attempt | CLOCK_PERIOD (ns) | Worst setup slack (ns), slow corner | Slack at tt corner (ns) | Result |
|---|---|---|---|---|
| 1 | 3.5 | -2.546 | +0.431 | Failed: setup violations |
| 2 | 4.0 | -2.027 | +0.929 | Failed: setup violations |
| 3 | 4.5 | -1.527 | +1.429 | Failed: setup violations |
| 4 | 5.0 | -1.027 | +1.929 | Failed: setup violations |
| 5 | 5.5 | -0.527 | +2.429 | Failed: setup violations |
| 6 | 6.0 | -0.037 | +2.911 | Failed: setup violations |
| 7 | 6.5 | -0.205 | +3.111 | Failed: setup violations |
| 8 | 7.0 | -0.116 | +3.526 | Failed: setup violations |
| 9 | 7.5 | -0.138 | +3.722 | Failed: setup violations |
| 10 | 8.0 | +0.362 | +4.222 | Passed: 0 DRC, 0 LVS, slack >= 0 |

Observation: the slack did not improve steadily with the period. From 3.5 to
6.0 ns the slow-corner critical path stayed at about 6.03 ns, so the slack
improved by exactly the 0.5 ns added to the period each time. Above 6.0 ns the
resizer relaxed the design (fewer repair buffers, 331 standard cells at 7.5 and
8.0 ns against 344 at 3.5 ns), the critical path grew to about 7.64 ns, and 7.5 ns
still failed by 0.138 ns. The 7.5 ns and 8.0 ns runs gave the same layout (same
cell count and wirelength), so 7.64 ns is the minimum period at the slow
corner for that layout.

#### Final results (CLOCK_PERIOD = 8.0 ns)

| Metric | Value |
|---|---|
| CLOCK_PERIOD used (ns) | 8.0 |
| Number of runs needed | 10 |
| Core area (um^2) | 17759.5 (die 22500 = 150 x 150) |
| Cells after synthesis (Part B) | 61 |
| Cells after place and route | 331 standard cells excluding fill; 1884 including 1299 decap cells, 254 fill cells |
| Kinds of cells added | 245 tap cells,1299 decap cells, 254 fill cells, 21 timing-repair buffers, 3 clock buffers |
| Wirelength (um) | 2518 |
| Setup slack (ns) | 0.362 (worst corner, max_ss_100C_1v60) |
| Post-route Fmax (MHz) | 1000 / (8.0 - 0.362) = 130.9 (slow corner); about 262 at the typical corner using the tt slack of 4.191 ns |
| Fmax from Part C (MHz) | 358.4 |
| DRC errors | 0 (Magic 0, KLayout 0) |
| LVS errors | 0 |


