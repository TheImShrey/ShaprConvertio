//
//  Date+Ext.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 12/02/24.
//

import Foundation
extension Date {
    func shortHandedDuration(since other: Date) -> String {
        guard self > other
        else {
            return "- \(other.shortHandedDuration(since: self))"
        }
        
        let interval = abs(self.timeIntervalSince(other))
        
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        let milliseconds = Int(interval * 1000) % 1000
        
        if hours > 0 {
            return "\(hours) H \(minutes) min"
        } else if minutes > 0 {
            return "\(minutes) min \(seconds) sec"
        } else {
            return "\(seconds) sec \(milliseconds) ms"
        }
    }
}
