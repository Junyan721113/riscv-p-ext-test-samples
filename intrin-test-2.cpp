#include <nds_intrinsic.h>
#include <stdio.h>
#include <stdint.h>

using namespace std;

int main() {
    int8x8_t a = (int8x8_t)0x8801FFFE7F008080L; 
    uint8x8_t const80 = (uint8x8_t)0L + 0x80;
    uint8x8_t b = (uint8x8_t)a;
    uint8x8_t c = __rv__v_clo8((uint8x8_t)a);
    uint8x8_t d = a - const80;
    printf("%016lx %016lx %016lx %016lx\n", a, b, c, d);
    return 0;
}
