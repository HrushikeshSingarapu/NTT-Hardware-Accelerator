Q = 3329

def mod_add(a, b):
    result = a + b
    if result >= Q:
        result -= Q
    return result

def mod_sub(a, b):
    result = a - b
    if result < 0:
        result += Q
    return result

def mod_mul(a, b):
    return (a * b) % Q