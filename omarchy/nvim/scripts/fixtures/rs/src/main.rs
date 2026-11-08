use fixture::{add, squares};

fn main() {
    let values = squares(5);
    let total = values.iter().fold(0, |acc, v| add(acc, *v));
    println!("total {}", total);
}
