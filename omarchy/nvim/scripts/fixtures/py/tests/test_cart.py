import pytest

from shop.cart import Cart, Item


def make_cart() -> Cart:
    cart = Cart()
    cart.add(Item("apple", 1.5, 2))
    cart.add(Item("pear", 2.0, 1))
    return cart


def test_subtotal():
    cart = make_cart()
    assert cart.subtotal() == 5.0


def test_discount_wrong():
    cart = make_cart()
    price = cart.discounted(10)
    assert price == 4.0


def test_raises_in_code():
    cart = make_cart()
    bad = cart.items[5]
    assert bad


@pytest.mark.parametrize("percent,want", [(0, 5.0), (100, 0.0)])
def test_param(percent, want):
    assert make_cart().discounted(percent) == want
