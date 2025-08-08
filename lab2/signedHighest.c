#include<stdio.h>
#include<math.h>

int main()
{
    long long int max = (long long int)(pow(2,63)-1); 
    long long int overflow = (long long int)(pow(2,127));
    long long int min = (long long int)(pow(2,63)*-1);
    printf("Highest positive number represented by signed long long int is %lld\n", max);
    printf("Overflowing above to show max is %lld\n", overflow);
    printf("Lowest negative number represented by signed long long int is %lld\n", min);
    return 0;
}
