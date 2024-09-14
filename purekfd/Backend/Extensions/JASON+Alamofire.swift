//
//  Featured.swift
//  purekfd
//
//  Created by Lrdsnow on 6/27/24.
//  Originally from https://github.com/delba/JASON/blob/master/Extensions/JASON+Alamofire.swift but rewritten to work with Alamofire 5
//

import Foundation
import Alamofire
import JASON

struct JASONResponseSerializer: DataResponseSerializerProtocol {
    typealias SerializedObject = JASON.JSON

    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> JASON.JSON {
        if let error = error {
            throw AFError.responseSerializationFailed(reason: .customSerializationFailed(error: error))
        }

        guard let validData = data else {
            throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
        }

        return JASON.JSON(validData)
    }
}

extension DataRequest {
    @discardableResult
    public func responseJASON(queue: DispatchQueue = .main, completionHandler: @escaping (AFDataResponse<JASON.JSON>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: JASONResponseSerializer(), completionHandler: completionHandler)
    }
}


