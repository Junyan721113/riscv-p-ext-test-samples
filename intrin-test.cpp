#include <rvp_intrinsic.h>
#include <stdio.h>
#include <stdint.h>

using namespace std;

int main() {
    uint64_t a = 0xABCDFFCDAFCDFBCD; 
    uint64_t b = 0x1111111111111111;
    uint64_t c = __rv_ukadd16(a, b);
    printf("%lx\n", c);
    return 0;
}
