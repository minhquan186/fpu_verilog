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
For more information about the program after compilation, type
```
.\test.exe --help
```
### 2. Generate test case using:
```
.\test.exe --gen
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
- Open Modelsim
- Change project directory to this code folder
- Add all the verilog code to the project
- In file ```fpu_tb.v``` on line 2, you should see:
```
parameter NUM_CASES = 10;
```
- Change the ```NUM_CASES``` according to the number of cases you gen before.
- Compile the code and simualte.
- Use ```run -all``` command in Verilog console or press **Run -All** button in the toolbar.
- The code will automatically stop running after loop through all test cases.
- You should see an output file named ```tb_output_gen.txt``` in your directory.
### 4. Evaluation:
Rerun the ```test.exe``` program with the following command:
```shell
.\test.exe --eval
```
- The terminal will display the nunber of errors if any along with the line that is differences from ground truth.
- If all the test cases are passed you will see ```Test passed!``` on your terminal.
