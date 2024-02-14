import CWinAppSDK
import CWinRT
import WindowsFoundation
import WinSDK

public enum WindowsAppSDKError: Error {
    case failedToInitialize
}

public enum ThreadingModel {
    case single
    case multi
}

public class WindowsAppRuntimeInitializer {
    private func processHasIdentity() -> Bool {
        var length: UInt32 = 0
        return GetCurrentPackageFullName(&length, nil) != APPMODEL_ERROR_NO_PACKAGE
    }

    public init(threadingModel: ThreadingModel = .single) throws  {
        let roInitParam = switch threadingModel {
            case .single: RO_INIT_SINGLETHREADED
            case .multi: RO_INIT_MULTITHREADED
        }

        try CHECKED(RoInitialize(roInitParam))

        guard !processHasIdentity() else {
            return
        }

        let result = MddBootstrapInitialize2(
            UInt32(WINDOWSAPPSDK_RELEASE_MAJORMINOR),
            WINDOWSAPPSDK_RELEASE_VERSION_TAG_SWIFT,
            .init(),
            MddBootstrapInitializeOptions(
                MddBootstrapInitializeOptions_OnNoMatch_ShowUI.rawValue
            )
        )
        guard result = S_OK else {
            throw WindowsAppSDKError.failedToInitialize
        }
    }

    deinit {
        RoUninitialize()
        if !processHasIdentity() {
            MddBootstrapShutdown()
        }
    }
}
