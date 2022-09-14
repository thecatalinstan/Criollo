//
//  Application.swift
//  
//
//  Created by Cătălin Stan on 16/09/2022.
//

@_exported import Criollo

public class Criollo {
    public static func applicationMain(_ delegate: ApplicationDelegate) throws {
        let res = __CRApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, delegate)
        if res != EXIT_SUCCESS {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(res), userInfo: [NSLocalizedDescriptionKey : strerror(res) ?? "The application returned an unknown error code."])
        }
    }
}
