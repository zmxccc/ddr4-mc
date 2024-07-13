com:
	iverilog -o wave *.v 

sim:
	vvp -n wave -lxt2

clean:
	rm wave* *.vcd