#if DEBUG

import Foundation
import os.log

final class Logger {
    static let shared = Logger()
    
    public func log(_ message: Any...) {
        let messageText = message.map { String(describing: $0) }.joined(separator: " ")
        
        os_log("%{public}@", "instaloader: \(messageText)")
    }
}

let log = Logger.shared.log as (Any?...) -> Void

#else

let log = { (_: Any?...) in }

#endif
