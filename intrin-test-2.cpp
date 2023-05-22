#include <rvp_intrinsic.h>
#include <stdio.h>
#include <stdint.h>

using namespace std;

int main() {
    uint16x4_t a = {0xABCD, 0xFFCD, 0xAFCD, 0xFBCD}; 
    uint16x4_t b = {0x1111, 0x1111, 0x1111, 0x1111};
    uint16x4_t c = __rv_v_ukadd16(a, b);
    printf("%lx\n", c);
    return 0;
}
