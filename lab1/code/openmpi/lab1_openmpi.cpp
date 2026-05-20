#include <mpi.h>
#include "sha256.h"
#include <iostream>
#include <cstdint>
#include <chrono>
#include <vector>
#include <algorithm>

std::string solve_crypto_puzzle(const std::string& str, uint puzzle_difficulty, int rank, int size)
{
    std::string nonce_needle(puzzle_difficulty, '0');
    std::string local_solution;
    int local_found = 0;

    SHA256 sha256;
    for (uint64_t k = 0; k < UINT64_MAX; ++k)
    {
        if (k % 4096ULL == 0ULL)
        {
            int global_found = 0;
            MPI_Allreduce(&local_found, &global_found, 1, MPI_INT, MPI_LOR, MPI_COMM_WORLD);
            if (global_found)
                break;
        }

        if (local_found)
            continue;

        const uint64_t i = rank + k * static_cast<uint64_t>(size);
        const std::string solution_candidate = str + std::to_string(i);
        const std::string hash_code = sha256(solution_candidate);

        if (hash_code.compare(0, puzzle_difficulty, nonce_needle) == 0)
        {
            local_solution = solution_candidate;
            local_found = 1;
        }
    }

    int global_found = 0;
    MPI_Allreduce(&local_found, &global_found, 1, MPI_INT, MPI_LOR, MPI_COMM_WORLD);
    if (!global_found)
        throw "No result found";

    int winner_rank = size;
    if (local_found)
        winner_rank = rank;

    int global_winner = size;
    MPI_Allreduce(&winner_rank, &global_winner, 1, MPI_INT, MPI_MIN, MPI_COMM_WORLD);

    int length = 0;
    if (rank == global_winner)
        length = static_cast<int>(local_solution.size());

    MPI_Bcast(&length, 1, MPI_INT, global_winner, MPI_COMM_WORLD);

    std::vector<char> buffer(static_cast<size_t>(length) + 1, '\0');
    if (rank == global_winner)
        std::copy(local_solution.begin(), local_solution.end(), buffer.begin());

    MPI_Bcast(buffer.data(), length + 1, MPI_CHAR, global_winner, MPI_COMM_WORLD);
    return std::string(buffer.data());
}

int main(int argc, char* argv[])
{
    MPI_Init(&argc, &argv);

    int world_size = 0;
    int world_rank = 0;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    if (argc < 2)
    {
        if (world_rank == 0)
        {
            std::cout << "Call application " << argv[0] << " with arguments [n]." << std::endl;
            std::cout << "Example:" << std::endl;
            std::cout << argv[0] << " 7" << std::endl;
        }
        MPI_Finalize();
        return 0;
    }

    if (argc > 2)
    {
        if (world_rank == 0)
            std::cout << "Incorrect arguments passed." << std::endl;
        MPI_Finalize();
        return 1;
    }

    const int difficulty = atoi(argv[1]);
    const std::string message("Hello World");

    if (world_rank == 0)
    {
        SHA256 sha256;
        std::cout << "Message:" << std::endl << message << std::endl;
        std::cout << "Hash:" << std::endl << sha256(message) << std::endl;
        std::cout << std::endl;
        std::cout << "Looking for nonce to solve crypto-puzzle with level " << difficulty
                  << " difficulty..." << std::endl;
        std::cout << "MPI processes: " << world_size << std::endl;
    }

    const auto t1 = std::chrono::high_resolution_clock::now();
    try
    {
        const std::string solution = solve_crypto_puzzle(message, difficulty, world_rank, world_size);

        if (world_rank == 0)
        {
            SHA256 sha256;
            std::cout << "Solution: " << std::endl << solution << std::endl;
            std::cout << "Hash:" << std::endl << sha256(solution) << std::endl;
        }
    }
    catch (const char* msg)
    {
        if (world_rank == 0)
            std::cout << msg << std::endl;
    }

    const auto t2 = std::chrono::high_resolution_clock::now();
    const auto duration_milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1);

    if (world_rank == 0)
        std::cout << duration_milliseconds.count() << " milliseconds\n";

    MPI_Finalize();
    return 0;
}
