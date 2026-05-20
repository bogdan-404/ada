#include <mpi.h>
#include "sha256.h"
#include <iostream> 
#include <cstdint>
#include <chrono>


int check_comandline_passed_arguments(int argc, char *argv[])
{
    char* app_name = argv[0];
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
    // std::cout << "Hash:" << std::endl << sha256(message) << std::endl;
    std::cout << std::endl << std::endl;
    std::cout << "Looking for nonce to solve crypto-puzzle with level " << difficulty << " difficulty" << "..." << std::endl;

    auto t1 = std::chrono::high_resolution_clock::now();

    // Initialize the MPI environment
    MPI_Init(NULL, NULL);

    // Get the number of processes
    int world_size;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);

    // Get the rank of the process
    int world_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    // Get the name of the processor
    char processor_name[MPI_MAX_PROCESSOR_NAME];
    int name_len;
    MPI_Get_processor_name(processor_name, &name_len);

    // Print off a hello message from each processor
    std::cout << "Hello from processor " << processor_name << ", rank " << world_rank << " out of " << world_size << " processors" << std::endl;

    // Insert your function instead of busy_work to solve crypto puzzle
    busy_work(message, difficulty);

    MPI_Finalize();

    // Insert code to output the result

    auto t2 = std::chrono::high_resolution_clock::now();
    auto duration_milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1);

    std::cout << duration_milliseconds.count() << " milliseconds\n";
}
