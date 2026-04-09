from modular_arithmetic import mod_add, mod_sub, mod_mul

Q = 3329
ZETA = 17

def br7(x):
    result = 0
    for i in range(7):
        result = (result << 1) | (x & 1)
        x >>= 1
    return result

ZETAS = [pow(ZETA, br7(i), Q) for i in range(128)]

def ntt(poly):
    n = len(poly)
    a = list(poly)
    k = 1
    length = 128
    
    while length >= 2:
        for start in range(0, n, 2 * length):
            zeta = ZETAS[k]
            k = k + 1
            for j in range(start, start + length):
                t = mod_mul(zeta, a[j + length])
                a[j + length] = mod_sub(a[j], t)
                a[j] = mod_add(a[j], t)
        length = length >> 1
    
    return a