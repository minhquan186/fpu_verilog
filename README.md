# Floating Point Unit Verilog
IEEE 754 Floating Point Unit written in Verilog
## Requirements:
- g++ compiler
- Modelsim
## How to run (Windows)
### 1. Compile test.cpp file using g++ compiler.
```
g++ -o test.exe test.cpp
```
### 2. Generate test case using:
```
.\test.exe --gen
```
or
```
.\test.exe -g
```
On your terminal you should see:
```
Number of cases to generate:
```
Enter the number of cases you want to generate. Let's take an example of 10
The output should be:
```
Number of cases to generate:  10
Generating...
Input testbench file generated successfully!
Input testbench file are saved as tb_input_gen.txt
```
You should see file ```tb_input_gen.txt``` in your directory.
### 3. Simulation:
