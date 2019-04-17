//
//  RequestFactory.swift
//  InTouchApp
//
//  Created by Михаил Борисов on 17/04/2019.
//  Copyright © 2019 Mikhail Borisov. All rights reserved.
//

import Foundation

struct RequestsFactory {
    static func photoImages() -> RequestConfig<PhotoParser> {
        return RequestConfig<PhotoParser>(request: PhotoRequestConfig(), parser: PhotoParser())
    }
}
