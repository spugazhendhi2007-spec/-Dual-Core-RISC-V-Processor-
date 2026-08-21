#!/usr/bin/env python3
"""
============================================================================
File: ai_ref_model.py
Project: Dual-Core RISC-V with AI Accelerator
Description: Bit-Exact Python Golden Reference Model for 8x8 INT8 AI Accelerator
============================================================================
"""

def relu(x):
    return max(0, x)

def relu6(x, shift):
    max_val = 6 << shift
    if x < 0:
        return 0
    elif x > max_val:
        return max_val
    return x

def saturate_int8(x):
    if x > 127:
        return 127
    elif x < -128:
        return -128
    return x

def gemm_int8_ref(weights, acts, bias=0, act_mode=1, scale_mult=1, scale_shift=0):
    """
    Bit-exact reference model for 8x8 INT8 matrix multiplication:
    Output = Sat8( Round_Shift( Act( (A * W) + Bias ) * Scale_Mult, Scale_Shift ) )
    """
    rows = len(acts)
    cols = len(weights[0])
    k_dim = len(weights)

    out = [[0 for _ in range(cols)] for _ in range(rows)]

    for r in range(rows):
        for c in range(cols):
            # INT32 Accumulation of INT8 products
            acc = 0
            for k in range(k_dim):
                acc += acts[r][k] * weights[k][c]

            # Bias Add
            biased = acc + bias

            # Activation function
            if act_mode == 1:
                activated = relu(biased)
            elif act_mode == 2:
                activated = relu6(biased, scale_shift)
            else:
                activated = biased

            # Scale & Rounding
            multiplied = activated * scale_mult
            if scale_shift > 0:
                rounded = (multiplied + (1 << (scale_shift - 1))) >> scale_shift
            else:
                rounded = multiplied

            # Saturation
            out[r][c] = saturate_int8(rounded)

    return out

if __name__ == "__main__":
    print("=== AI Accelerator Golden Reference Model Validation ===")
    # 8x8 Identity * 8x8 Matrix of 2s
    W = [[1 if i == j else 0 for j in range(8)] for i in range(8)]
    A = [[2 for _ in range(8)] for _ in range(8)]
    res = gemm_int8_ref(W, A, bias=0, act_mode=1, scale_mult=1, scale_shift=0)
    print("Sample Output Matrix (Top Row):", res[0])
    assert res[0] == [2] * 8, "Reference model check failed!"
    print(">>> Python Golden Reference Model self-test passed successfully! <<<")
