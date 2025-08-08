#include<stdio.h>
#include<math.h>

int main()
{
    unsigned long long int max = (unsigned long long int)(pow(2,64)-1); 
    unsigned long long int overflow = (unsigned long long int)(pow(2,127));
    unsigned long long int min = (unsigned long long int)(0);
    printf("Highest number represented by unsigned long long int is %llu\n", max);
    printf("Overflowing above to show max is %llu\n", overflow);
    printf("Lowest number represented by unsigned long long int is %llu\n", min);
    return 0;
}
