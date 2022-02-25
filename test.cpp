#include <iostream>
#include <random>
#include <cmath>
#include <bitset>
#include <string>
#include <limits>
#include <fstream>

const float LIMIT = std::pow(10, 15);

float random_float(float start, float end) {
    std::random_device rd;
    std::default_random_engine generator(rd());
    std::uniform_real_distribution <float> distribution(start, end);
    return distribution(generator);
}

int random_int(int start, int end) {
    std::random_device rd;
    std::default_random_engine generator(rd());
    std::uniform_int_distribution <int> distribution(start, end);
    return distribution(generator);
}

int bin_to_hex(std::string bin)
{
    std::bitset<32> set(bin);      
    int hex = set.to_ulong();   
    return hex;
}

float bin32_to_dec(std::string bin)
{
    int HexNumber = bin_to_hex(bin);
 
    bool negative  =   (HexNumber & 0x80000000); 
    int  exponent  =   (HexNumber & 0x7f800000) >> 23;   
    int sign = negative ? -1 : 1;
 
    // Subtract 127 from the exponent
    exponent -= 127;
 
    // Convert the mantissa into decimal using the last 23 bits
    int power = -1;
    float total = 0.0;
    for (int i = 0; i < 23; i++)
    {
        int c = bin[i + 9] - '0';
        total += (float) c * (float) pow(2.0, power);
        power--;
    }
    total += 1.0;
 
    float dec = sign * (float) pow(2.0, exponent) * total;
 
    return dec;
}
 
// Convert the decimal into the 32-bit binary based on IEEE-754 format
std::string dec_to_bin32(float dec)
{
    union
    {
        float input;   
        int   output;
    } data;
 
    data.input = dec;
 
    std::bitset<sizeof(float) * CHAR_BIT>   bits(data.output);

    std::string str = bits.to_string<char, std::char_traits<char>, std::allocator<char> >();
    return str;
}

void tb_gen(int cases_num)
{
    float a, b, res;
    int rand_op;

    std::string opcode;
    std::string error;

    std::ofstream file1("tb_input_gen.txt");
    std::ofstream file2("tb_output_gen.txt");

    for (int i = 0; i < cases_num; i++) {
        a = random_float(-LIMIT, LIMIT);
        b = random_float(-LIMIT, LIMIT);
        rand_op = random_int(0,3);

        opcode = std::bitset<2>(rand_op).to_string();
        std::string bin_a, bin_b, bin_res;

        bin_a = dec_to_bin32(a);
        bin_b = dec_to_bin32(b);
        
        if (opcode == "00") {
            res = a + b;
            bin_res = dec_to_bin32(res);
            error = "000";
        } 
        else if (opcode == "01") {
            res = a - b; 
            bin_res = dec_to_bin32(res); 
            error = "000"; 
        }
        else if (opcode == "10") {
            res = a * b; 
            bin_res = dec_to_bin32(res); 
            error = "000"; 
        }
        else if (opcode == "11") {
            if (b == 0) {
                bin_res = "01111111100000000000000000000000";
                error = "100";
            }
            else {
                res = a / b;
                bin_res = dec_to_bin32(res); 
                error = "000";      
            }     
        }
        else {
            std::cout << "Invalid";
        }

        // std::cout << opcode << " " << bin_a << " " << bin_b << " " << bin_res << " " << error << std::endl;
        
        file1 << opcode << bin_a << bin_b << std::endl;
        file2 << bin_res << error << std::endl;

    }

    file1.close();
    file2.close();
}

void res_compare()
{
    std::ifstream truth("tb_output_gen.txt");
    std::ifstream fpu_gen("output_tb_fpu.txt");
    
    if (!truth){
        fpu_gen.close();
        throw std::runtime_error("Failed to open tb_output_gen.txt");
    }
    if (!fpu_gen){
        truth.close();
        throw std::runtime_error("Failed to open output_tb_fpu.txt");
    }

    int count1 = 0;
    int count2 = 0;

    std::string tmp_str = "";

    while(!truth.eof()) {
        std::getline(truth, tmp_str);
        count1++;
    }

    while(!fpu_gen.eof()) {
        std::getline(fpu_gen, tmp_str);
        count2++;
    }

    truth.clear();
    truth.seekg(0, std::ios::beg);

    fpu_gen.clear();
    fpu_gen.seekg(0, std::ios::beg);

    if (count1 != count2) {
        std::cout << "Number of lines does not match." << std::endl;
        std::cout << "tb_output_gen.txt has: " << count1 << " lines\n"
                  << "output_tb_fpu.txt has: " << count2 << " lines\n";
    }
    else{
        std::string tmp_str1 = "";
        std::string tmp_str2 = "";
        int index = 0;
        int error_count = 0;
        while(!truth.eof()) {
            std::getline(truth, tmp_str1);
            std::getline(fpu_gen, tmp_str2);
            index++;
            if(tmp_str1 != tmp_str2) {
                std::cout << "Differences at line " << index << std::endl
                          << "Truth: \t\t" << tmp_str1 << std::endl
                          << "FPU Output: \t" << tmp_str2 << std::endl;
                error_count++;
            }
        }
        if (error_count != 0) {
            std::cout << "Test not passed! There are " << error_count << " error(s)!" << std::endl;
        }
        else {
            std::cout << "Test passed!" << std::endl;
        }
    }

    truth.close();
    fpu_gen.close();

}

int main(int argc, char* argv[]) {
    int num_cases = 0;

    if (argc == 1){
        std::cout   << "Please specify your option.\nType '--help' or '-h' to open a help message." << std::endl; 
                    
    }
    else if (argc == 2){
        if ((argv[1] == std::string("--help")) || (argv[1] == std::string("-h"))){
            std::cout   << "Options:\n"
                        << "-e  --eval\t\tEvaluate the result from generated file\n"                   
                        << "-g  --gen\t\tGenerate testbench\n"                     
                        << "-h  --help\t\tShow this very help message\n"                    
                        << std::endl;
        }
        else if ((argv[1] == std::string("--gen")) || (argv[1] == std::string("-g"))){
            std::cout << "Number of cases to generate:  ";
            std::cin >> num_cases;
            std::cout << "Generating..." << std::endl;
            tb_gen(num_cases);
            std::cout << "Input testbench file generated successfully!" << std::endl;
            std::cout << "Input testbench file are saved as tb_input_gen.txt" << std::endl;
        }
        else if ((argv[1] == std::string("--eval")) || (argv[1] == std::string("-e"))){
            res_compare();
        }
        else{
            std::cout   << "Invalid arguments!" << std::endl
                        << "Please check help page using --help or -h for more information."
                        << std::endl;
        }
    }
    else{
        std::cout << "Too many arguments!" << std::endl;
    }
    return 0;
}

