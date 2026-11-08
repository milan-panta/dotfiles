# $(URL)
import sys

input = lambda: sys.stdin.readline().rstrip("\r\n")
out = []


def ints():
    return list(map(int, input().split()))


def dbg(*args):
    print(*args, file=sys.stderr)


def main():
    solve()
    print("\n".join(map(str, out)))


def solve():
    pass


main()
