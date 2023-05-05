# ConwayArmSim
This project simulates Conway's Game of Life using a kd-tree in arm 64 bit assembly and C. It is a CO course final project (Instructor [Dr. Gilbert Tekli](https://www.linkedin.com/in/gilbert-tekli/)) in collaboration with my teammate [Ms. Zeina Mershad](https://www.linkedin.com/in/zeina-mershad-b51720262/).

## Requirements:
  * Python 3 with NumPy and Matplotlib libraries
  * GCC
  * AArch64 cross-compilation toolchain, including aarch64-linux-gnu-as and aarch64-linux-gnu-ld
  * Emulator to run ARM AArch64 executables (if the OS doesn't support it)

We recommend using [qemu-user](https://www.qemu.org/docs/master/user/main.html) as the emulator, which can be installed on Ubuntu using the following command:
	`sudo apt-get install qemu-user`

## Run
To run the project, execute the simulate.sh script to define the necessary bash functions:

  ```bash 
  source simulate.sh
  ```
  

To simulate 100 generations from ARM code, run the following command:
```bash
sim-from-arm 100
  ```

To simulate 100 generations from C code, run the following command:
```bash 
sim-from-c 100
  ```

Both commands generate a file called simulation containing the simulation data. This file is then passed to the visualize.py Python program to display the results.

## Initialize First Generation
### Arm
Use the following code snippet. x value is in `x1` and y value in `x2`.
```asm
	adr x0, tree
	ldr x0, [x0]
	mov x1, #0
	mov x2, #0
	bl insert
```
Add one snippet for each node after initializing the tree. Our pre-defined generation starts at line 60.

### C
Use the following function in main: 
```C
insert(r, 0, 0);
``` 
