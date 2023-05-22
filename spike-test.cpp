#include <cstdio>

using namespace std;

int main() {
    unsigned long a = 0xABCDFFCDAFCDFBCD;
    unsigned long b = 0x1111111111111111;
    unsigned long c = a + b;
    printf("%lx\n", c);
    return 0;
}
