"""Run me: reads input() and calls into the cart."""
import asyncio

from shop.cart import Cart, Item, count_to


async def fetch(n: int) -> int:
    await asyncio.sleep(0.01)
    return n * 2


async def gather_all() -> list[int]:
    results = await asyncio.gather(*(fetch(i) for i in range(3)))
    return list(results)


def main() -> None:
    name = input("name: ")
    cart = Cart()
    cart.add(Item(name, 2.5, 4))
    print("subtotal", cart.subtotal())
    print("sum", count_to(1000))
    print("async", asyncio.run(gather_all()))


if __name__ == "__main__":
    main()
