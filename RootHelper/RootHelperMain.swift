//
//  RootHelperMain.swift
//  PureKFD
//
//  Created by Nick Chan on 12/12/2023.
//

import Foundation

func RootHelperMain() -> Int32 {
    if (CommandLine.argc < 2) {
        return -1;
    }
    
    switch CommandLine.arguments[1] {
        case "remount-preboot":
        
        let ret = String(mount_check("/private/preboot"))
        
        if ret == "All Good!" {
            return 0
        }
        
        return -1;
        
    default:
        fputs("unknown argument passed to rootHelper\n", stderr)
        return -1;
    }
}
