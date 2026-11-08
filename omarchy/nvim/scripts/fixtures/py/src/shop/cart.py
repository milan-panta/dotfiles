"""A small cart, so the debugger has real data to show."""
from dataclasses import dataclass, field


@dataclass
class Item:
    name: str
    price: float
    qty: int = 1

    def total(self) -> float:
        return self.price * self.qty


@dataclass
class Cart:
    items: list[Item] = field(default_factory=list)
    meta: dict[str, int] = field(default_factory=dict)

    def add(self, item: Item) -> None:
        self.items.append(item)
        self.meta[item.name] = item.qty

    def subtotal(self) -> float:
        running = 0.0
        for item in self.items:
            running += item.total()
        return running

    def discounted(self, percent: float) -> float:
        """
        >>> Cart([Item("a", 10.0)]).discounted(50)
        5.0
        """
        rate = percent / 100
        return self.subtotal() * (1 - rate)


def count_to(limit: int) -> int:
    total = 0
    for i in range(limit):
        total += i
    return total


def make_big() -> dict[str, list[int]]:
    return {"big": list(range(5000)), "nested": [[i, i * 2] for i in range(200)]}
