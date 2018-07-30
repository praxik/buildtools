#include <stdint.h>

//This program compiles when unsigned long and uint64_t are the same type
template< typename T, typename U > struct IsSame;
template< typename T > struct IsSame< T, T >{};

int main()
{
    IsSame< uint64_t, unsigned long > FailsWhenNotSameTypes;
    return 0;
}
