#include <stdio.h>
#include <stdint.h>

using namespace std;

int main() {
    unsigned long a = 0xABCDFFCDAFCDFBCD; 
    unsigned long b = 0x1111111111111111;
    unsigned long c;
    asm volatile("UKADD16 %0, %1, %2" : "=r" (c) : "r" (a), "r" (b));
    printf("%lx\n", c);
    return 0;
}
