def blakely_mult(A, B, n):
    R = 0

    for bit in bin(A)[2:]:
        R = R << 1

        if bit == '1':
            R += B

        if R >= n:
            R -= n

        if R >= n:
            R -= n
    return R

def rsa_encrypt(m, e, n):
    ACC = 1
    BASE = m

    for bit in bin(e)[2:]:
        ACC = blakely_mult(ACC, ACC, n)
        if bit == '1':
            ACC = blakely_mult(ACC, BASE, n)

    return ACC

e = 5
n = 323
m = 'A'

ciphertext = rsa_encrypt(ord(m), e, n)
print(f"{m} (ASCII: {ord(m)}) -> Ciphertext: {ciphertext}")

decrypted = rsa_encrypt(ciphertext, 173, n)
print(f"Decrypted ciphertext: {decrypted} (ASCII: {chr(decrypted)})")
