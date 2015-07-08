//  NVShapeFileDatabase.c
//  GMMobile

#include "NVShapeFileDatabase.h"
#include "CCodeLibrary/CCodeTypes.h"

static LPSTR  BytesToBlob(LPBYTE pBytes, int nBytes)
{
    LPSTR pBlob = malloc(nBytes * 2 +4);
    int i, lBlob = 0;
    
    for (i = 0; i < nBytes; i++,lBlob+=2)
    {
        sprintf(&pBlob[lBlob], "%2.2x", pBytes[i]);
    }
    pBlob[lBlob] = 0;
    return pBlob;
}