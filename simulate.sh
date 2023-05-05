#! /bin/bash

function arm-assemble () {
	gcc -E $1.S > $1.s && aarch64-linux-gnu-as $1.s -o $1.o && aarch64-linux-gnu-ld $1.o -o $1
}

function sim-from-c(){
	touch simulation && gcc c-sim.c -o c-sim && ./c-sim $1 && python3 -m visualize
}

function sim-from-arm(){
	touch simulation && arm-assemble main && ./main $1 > simulation && python3 -m visualize
}


