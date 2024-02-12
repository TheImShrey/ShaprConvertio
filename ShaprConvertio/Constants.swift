//
//  Constants.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 10/02/24.
//

import Foundation
enum Filetypes: String {
    case shapr
    case obj
    case jpeg
    case heif
    case png

}

struct Constants {
    struct Conversion {
        //    static let inputType = Filetypes.test
        //    static let outputType = Filetypes.test
        static let inputType = Filetypes.heif
        static let outputType = Filetypes.obj
    }
}


enum AppError: Error {
    case somethingWentWrong
}
