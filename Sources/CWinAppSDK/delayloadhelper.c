#include <wtypesbase.h>
#include <minwindef.h>
#include <winnt.h>
#include "delayimp.h"
FARPROC WINAPI delayHook(unsigned dliNotify, PDelayLoadInfo pdli)
{
    switch (dliNotify) {
        case dliFailLoadLib :
            if (strcmp(pdli->szDll, "Microsoft.WindowsAppRuntime.Boostrap.dll") == 0) {
                return (FARPROC)LoadLibraryW(L"swift-windowsappsdk_WinAppSDK.resources\\Microsoft.WindowsAppRuntime.Bootstrap.dll");
            }
            break;

        default :

            return NULL;
    }

    return NULL;
}

const PfnDliHook __pfnDliNotifyHook2 = delayHook;
const PfnDliHook __pfnDliFailureHook2 = delayHook;
