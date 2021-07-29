//
//  LXResponse.swift
//  WebServiceDemo
//
//  Created by Apple on 2021/7/29.
//

import Foundation
import YYModel


class LXBaseResponse {
    let json: [String: Any]
    
    var code: Int {
        guard let temp = json["code"] as? Int else {
            return -1
        }
        return temp
    }
    
    var message: String? {
        guard let temp = json["message"] as? String else {
            return nil
        }
        return temp
    }
    
    var jsonData: Any? {
        guard let temp = json["data"] else {
            return nil
        }
        return temp
    }
    
    init?(data: Any) {
        guard let temp = data as? [String: Any] else {
            return nil
        }
        self.json = temp
    }
    
    func jsonToData(_ object: Any) -> Data? {
        if !JSONSerialization.isValidJSONObject(object) {
            return nil
        }
        
        return try? JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions.prettyPrinted)
    }
    
    func dataToJson(_ object: Data) -> String? {
        return try? JSONSerialization.jsonObject(with: object, options: JSONSerialization.ReadingOptions.mutableContainers) as? String
    }
}

class LXModelResponse<T>: LXBaseResponse where T: NSObject {
    var data: T? {
        guard code == ResponseCode.successResponseStatusCode, let tempJsonData = jsonData as? [AnyHashable: Any] else {
            return nil
        }
        return T.yy_model(with: tempJsonData)
    }
}

class LXModelArrayResponse<T>: LXBaseResponse where T: NSObject {
    var dataArray: [T]? {
        guard code == ResponseCode.successResponseStatusCode, let tempJsonArray = jsonData as? [[AnyHashable: Any]] else {
            return nil
        }
        
        return tempJsonArray.map { dic in
            return T.yy_model(with: dic) ?? T.init()
        }
    }
}
