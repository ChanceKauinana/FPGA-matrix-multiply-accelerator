from pathlib import Path
import random

DATA_MIN = -128
DATA_MAX = 127


def matmul_2x2(A, B):
    """
    A and B are 2x2 matrices represented as lists of lists.
    Returns C = A * B, which is also a 2x2 matrix.
    """
    c00 = A[0][0] * B[0][0] + A[0][1] * B[1][0]
    c01 = A[0][0] * B[0][1] + A[0][1] * B[1][1]
    c10 = A[1][0] * B[0][0] + A[1][1] * B[1][0]
    c11 = A[1][0] * B[0][1] + A[1][1] * B[1][1]

    return [
        [c00, c01],
        [c10, c11],
    ]


def rand_s8():
    """
    Returns a random signed 8-bit integer in the range [-128, 127].
    """
    return random.randint(DATA_MIN, DATA_MAX)


def write_case(file, A, B):
    C = matmul_2x2(A, B)

    values = [
        A[0][0], A[0][1], A[1][0], A[1][1],
        B[0][0], B[0][1], B[1][0], B[1][1],
        C[0][0], C[0][1], C[1][0], C[1][1],
    ]

    file.write(" ".join(str(v) for v in values) + "\n")


def main():
    random.seed(0)

    repo_root = Path(__file__).resolve().parents[1]
    out_path = repo_root / "sim" / "matmul_2x2_vectors.txt"

    num_random_tests = 100

    with open(out_path, "w") as file:
        # Directed positive test case
        A = [[1, 2], [3, 4]]
        B = [[5, 6], [7, 8]]
        write_case(file, A, B)

        # Directed signed test case
        A = [[-1, 2], [3, -4]]
        B = [[5, -6], [-7, 8]]
        write_case(file, A, B)

        # Random test cases
        for _ in range(num_random_tests):
            A = [[rand_s8(), rand_s8()], [rand_s8(), rand_s8()]]
            B = [[rand_s8(), rand_s8()], [rand_s8(), rand_s8()]]
            write_case(file, A, B)

    print(f"Wrote test vectors to: {out_path}")
    print(f"Total tests: {num_random_tests + 2}")


if __name__ == "__main__":
    main()