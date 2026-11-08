pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

pub fn squares(n: i32) -> Vec<i32> {
    let mut out = Vec::new();
    for i in 0..n {
        out.push(i * i);
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ok() {
        assert_eq!(add(1, 2), 3);
    }

    #[test]
    fn bad() {
        let got = add(1, 2);
        assert_eq!(got, 4);
    }
}
