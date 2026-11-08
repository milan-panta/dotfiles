#include <bits/stdc++.h>
using namespace std;

int main() {
    int n;
    cin >> n;
    vector<long long> a(n);
    for (auto& x : a) cin >> x;
    long long sum = 0;
    for (int i = 0; i < n; i++) {
        sum += a[i];
    }
    map<long long, int> freq;
    for (auto x : a) freq[x]++;
    cout << sum << "\n";
    return 0;
}
