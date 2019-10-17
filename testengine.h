#define extern FAIL() printf("\nfailure in %s() line %d\n", __func__, __LINE__)
#define extern _assert(test) do { if (!(test)) { FAIL(); return 1; } } while(0)
#define extern _verify(test) do { int r=test(); tests_run++; if(r) return r; } while(0)