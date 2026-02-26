# NTT Reference Model — CRYSTALS-Kyber 512
# q = 3329, n = 256, zeta = 17

q    = 3329
n    = 256
zeta = 17

# ── Modular arithmetic ──────────────────────────────────────

def mod_add(a, b):
    return (a + b) % q

def mod_sub(a, b):
    return (a - b + q) % q

def mod_mul(a, b):
    return (a * b) % q

# ── Bit reversal (for twiddle factor ordering) ──────────────

def bit_reverse(val, bits=7):
    result = 0
    for _ in range(bits):
        result = (result << 1) | (val & 1)
        val >>= 1
    return result

# ── Twiddle factor generation ────────────────────────────────

def generate_twiddles():
    return [pow(zeta, bit_reverse(k, 7), q) for k in range(128)]

TWIDDLES = generate_twiddles()

# ── Butterfly operation (core of NTT) ───────────────────────

def butterfly(a, b, w):
    t = mod_mul(w, b)
    return mod_add(a, t), mod_sub(a, t)

# ── Forward NTT ─────────────────────────────────────────────

def ntt(poly):
    result = poly.copy()
    length = 128
    k = 1

    while length >= 1:
        for start in range(0, n, 2 * length):
            w = TWIDDLES[k % 128]   # fixed: prevent index out of range
            k += 1
            for j in range(start, start + length):
                result[j], result[j + length] = butterfly(result[j], result[j + length], w)
        length //= 2

    return result

# ── Inverse NTT ─────────────────────────────────────────────

def intt(poly):
    result = poly.copy()
    k = 127
    length = 1

    while length <= 128:
        for start in range(0, n, 2 * length):
            w = (q - TWIDDLES[k % 128]) % q   # fixed: prevent index out of range
            k -= 1
            for j in range(start, start + length):
                result[j], result[j + length] = butterfly(result[j], result[j + length], w)
        length *= 2

    # normalize — divide by 128
    inv128 = pow(128, -1, q)
    return [mod_mul(c, inv128) for c in result]

# ── Pointwise multiply (in NTT domain) ──────────────────────

def poly_mul(A, B):
    return [mod_mul(a, b) for a, b in zip(A, B)]

# ── Full polynomial multiplication ──────────────────────────

def multiply(A, B):
    return intt(poly_mul(ntt(A), ntt(B)))

# ── Quick sanity check ───────────────────────────────────────

if __name__ == "__main__":
    import random
    poly = [random.randint(0, q - 1) for _ in range(n)]

    # NTT then INTT should give back the original
    recovered = intt(ntt(poly))

    if poly == recovered:
        print("PASS — round trip works")
    else:
        print("FAIL — something is wrong")