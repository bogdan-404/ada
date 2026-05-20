#include <omp.h>
#include <iostream> 
#include <cstdint>
#include <chrono>
#include "sha256.h"


int check_comandline_passed_arguments(int argc, char *argv[])
{
    char* app_name = argv[0];
    std::cout << "Count of arguments passed: " << argc << std::endl;
    if(argc == 1){
        std::cout << "Call application "<< app_name << " with arguments [n]." << std::endl;
        std::cout << "Example:" << std::endl;
        std::cout << app_name <<" 7 -- Application will try to solve crypto puzzle SHA256 with nonce that will generate 7 trailing 0 of the hashed message." << std::endl;
        std::cout << app_name <<" 8 -- Application will try to solve crypto puzzle SHA256 with nonce that will generate 8 trailing 0 of the hashed message." << std::endl;

        exit(0);
    }
    if(argc > 2)
    {
        std::cout << "Incorrect arguments passed." << std::endl;
        std::cout << "Call application "<< app_name << " for help message" << std::endl;
        exit(1);
    }
    return 0;
}

std::string busy_work(std::string str, uint puzzle_difficulty)
{
    volatile int c;
    std::string hash_code;
    SHA256 sha256;
    for(uint64_t i=0; i < UINT64_MAX; i++){
        std::string solution_candidate = "Hello World" + std::to_string(i);
        hash_code = sha256(solution_candidate);
    }
    return hash_code;
}


int main (int argc, char *argv[]) 
{
    check_comandline_passed_arguments(argc, argv);

    int difficulty = atoi(argv[1]);
    SHA256 sha256;
    const std::string message("Hello World");

    std::cout << "Message:" << std::endl << message << std::endl;
    std::cout << "Hash:" << std::endl << sha256(message) << std::endl;
    std::cout << std::endl << std::endl;
    std::cout << "Looking for nonce to solve crypto-puzzle with " << difficulty << " difficulty" << "..." << std::endl;
    auto t1 = std::chrono::high_resolution_clock::now();

    std::cout << "Application with OpenMP parameters:" << std::endl;

    int total_threads, current_thread_id;
    #pragma omp parallel num_threads(8) private(total_threads, current_thread_id)
    {
        current_thread_id = omp_get_thread_num();
        total_threads = omp_get_num_threads();
        std::cout << "Total threads: " << total_threads << std::endl;
        std::cout << "Current thread: " << current_thread_id << std::endl;
        
        // Insert your function here to solve crypto puzzle
        busy_work(message, difficulty);
    }
    // Insert code to output the result

    auto t2 = std::chrono::high_resolution_clock::now();
    auto duration_milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1);

    std::cout << duration_milliseconds.count() << " milliseconds\n";

}
