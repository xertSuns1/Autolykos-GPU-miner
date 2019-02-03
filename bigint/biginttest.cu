#include <stdio.h>
#include <stdlib.h>
#include <cuda.h>

#include "kernel.h"

#define CUDA_CALL(x) do { if((x) != cudaSuccess) { \
printf("CUDA error at %s:%d\n",__FILE__,__LINE__); \
return EXIT_FAILURE;}} while(0)

/// Little-endian
/// 8 * 32 bits
/// q == [q0, q1, q2, q3, 0, 0, 0, 0x10000000]
/// 4 * 64 bits
/// q == [Q0, Q1, 0, 0x1000000000000000]

// 32 bits
#define q3 0x14DEF9DE
#define q2 0xA2F79CD6
#define q1 0x5812631A
#define q0 0x5CF5D3ED

// 64 bits
#define Q1 0x14DEF9DEA2F79CD6
#define Q0 0x5812631A5CF5D3ED

#define Q0_1 0x5812631A5CF5D3EC
#define Q0_2 0x5812631A5CF5D3EB
#define Q0_3 0x5812631A5CF5D3EA

int main(int argc, char *argv[])
{
    uint64_t * x_h = (uint64_t *)malloc(5 * sizeof(uint64_t));
    uint64_t * y_h = (uint64_t *)malloc(4 * sizeof(uint64_t));
    uint64_t * res_h = (uint64_t *)malloc(8 * sizeof(uint64_t));

    // x_h[3] = 0x1000000000000000;
    // x_h[2] = 0;
    // x_h[1] = Q1;
    // x_h[0] = Q0_1;
    // 
    // y_h[3] = 0x1000000000000000;
    // y_h[2] = 0;
    // y_h[1] = Q1;
    // y_h[0] = Q0_1;

    x_h[3] = 0;
    x_h[2] = 0;
    x_h[1] = 0;
    x_h[0] = 1;
    
    y_h[3] = 0x1000000000000000;
    y_h[2] = 0;
    y_h[1] = Q1;
    y_h[0] = Q0;

    uint32_t * x_d;
    uint32_t * y_d;
    uint64_t * res_d;
    
    CUDA_CALL(cudaMalloc((void **)&x_d, 10 * sizeof(uint32_t)));
    CUDA_CALL(cudaMalloc((void **)&y_d, 8 * sizeof(uint32_t)));
    CUDA_CALL(cudaMalloc((void **)&res_d, 8 * sizeof(uint64_t)));

    /// //====================================================================//
    /// //  Multiplication mod q test
    /// //====================================================================//
    /// for (int i = 1; i < 0xFF; ++i)
    /// {
    ///     x_h[0] = Q0 - i;
    ///     for (int j = 1; j < 0xFF; ++j)
    ///     {
    ///         y_h[0] = Q0 - j;
    ///         CUDA_CALL(cudaMemcpy(
    ///             x_d, (uint32_t *)x_h, 8 * sizeof(uint32_t),
    ///             cudaMemcpyHostToDevice
    ///         ));
    ///         CUDA_CALL(cudaMemcpy(
    ///             y_d, (uint32_t *)y_h, 8 * sizeof(uint32_t),
    ///             cudaMemcpyHostToDevice
    ///         ));

    ///         mul<<<1, 1>>>(x_d, y_d, (uint32_t *)res_d);
    ///         mod_q<<<1, 1>>>(8, res_d);

    ///         CUDA_CALL(cudaMemcpy(
    ///             res_h, res_d, 8 * sizeof(uint64_t), cudaMemcpyDeviceToHost
    ///         ));

    ///         //printf("%#lx, %#lx,\n%#lx, %#lx\n", res_h[7], res_h[6], res_h[5], res_h[4]);

    ///         if (
    ///             res_h[3] > 0 || res_h[2] > 0
    ///             || res_h[1] > 0 || res_h[0] != i * j
    ///         ) {
    ///             printf(
    ///                 "%#lx, %#lx, %#lx, %#lx ",
    ///                 res_h[3], res_h[2], res_h[1], res_h[0]
    ///             );
    ///             printf("\ti * j = %#x\n", i * j);
    ///         }
    ///     }
    ///     printf("i = %d\n", i);
    /// }

    /// //====================================================================//
    /// //  Addition mod q test
    /// //====================================================================//
    /// for (int i = 1; i < 0xFF; ++i)
    /// {
    ///     for (int j = 1; j < 0xFF; ++j)
    ///     {
    ///         x_h[3] = 0x1000000000000000;
    ///         x_h[2] = 0;
    ///         x_h[1] = Q1;
    ///         x_h[0] = Q0 + i;
    ///         y_h[0] = Q0 + j;
    ///         CUDA_CALL(cudaMemcpy(
    ///             x_d, (uint32_t *)x_h, 8 * sizeof(uint32_t),
    ///             cudaMemcpyHostToDevice
    ///         ));
    ///         CUDA_CALL(cudaMemcpy(
    ///             y_d, (uint32_t *)y_h, 8 * sizeof(uint32_t),
    ///             cudaMemcpyHostToDevice
    ///         ));
    ///         CUDA_CALL(cudaMemset((void *)(x_d + 8), 0, 2 * sizeof(uint32_t)));


    ///         addc<<<1, 1>>>(x_d, x_d + 8, y_d);
    ///         mod_q<<<1, 1>>>(5, (uint64_t *)x_d);

    ///         CUDA_CALL(cudaMemcpy(
    ///             x_h, (uint64_t *)x_d, 5 * sizeof(uint64_t),
    ///             cudaMemcpyDeviceToHost
    ///         ));

    ///         if (
    ///             x_h[4] > 0 || x_h[3] > 0 || x_h[2] > 0
    ///             || x_h[1] > 0 || x_h[0] != i + j
    ///         ) {
    ///             printf(
    ///                 "%#lx, %#lx, %#lx, %#lx, %#lx ",
    ///                 x_h[4], x_h[3], x_h[2], x_h[1], x_h[0]
    ///             );
    ///             printf("\ti + j = %#x\n", i + j);
    ///         }
    ///     }
    ///     printf("i = %d\n", i);
    /// }

    //====================================================================//
    //  Multiplication mod q test
    //====================================================================//
    for (int j = 1; j < 0xFF; ++j)
    {
        x_h[0] = j;
        CUDA_CALL(cudaMemcpy(
            x_d, (uint32_t *)x_h, 8 * sizeof(uint32_t),
            cudaMemcpyHostToDevice
        ));
        CUDA_CALL(cudaMemcpy(
            y_d, (uint32_t *)y_h, 8 * sizeof(uint32_t),
            cudaMemcpyHostToDevice
        ));

        mul<<<1, 1>>>(x_d, y_d, (uint32_t *)res_d);
        //mod_q<<<1, 1>>>(8, res_d);

        CUDA_CALL(cudaMemcpy(
            res_h, res_d, 8 * sizeof(uint64_t), cudaMemcpyDeviceToHost
        ));

        //printf("%#lx, %#lx,\n%#lx, %#lx\n", res_h[7], res_h[6], res_h[5], res_h[4]);

        printf(
            "%lx, %#lx, %#lx, %#lx, %#lx ",
            res_h[4], res_h[3], res_h[2], res_h[1], res_h[0]
        );
        printf("\tj = %#x\n", j);

        if (res_h[4] > 0)
        {
            break;
        }
    }

    CUDA_CALL(cudaFree(x_d));
    CUDA_CALL(cudaFree(y_d));
    CUDA_CALL(cudaFree(res_d));

    free(x_h);
    free(y_h);
    free(res_h);

    printf("OK\n");
    return EXIT_SUCCESS;
}

