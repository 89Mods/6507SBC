#include "Vtb.h"
#include "verilated.h"
#include <iostream>

static Vtb top;

void clocks(int c) {
	for(int i = 0; i < c*2; i++) {
		Verilated::timeInc(1);
		top.clk = !top.clk;
		top.eval();
	}
}

double sc_time_stamp() { return 0; }

int main(int argc, char** argv, char** env) {
	Verilated::traceEverOn(true);
	top.clk = 0;
	top.rstb = 0;
	clocks(4);
	top.rstb = 1;
	int counter = 0;
	while(!Verilated::gotFinish()) {
		Verilated::timeInc(1);
		top.clk = !top.clk;
		top.eval();
		counter++;
		//if(counter >= 65536*128) break;
	}
	top.final();
	return 0;
}
