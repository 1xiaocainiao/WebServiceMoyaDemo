//
//  LXResponse.swift
//  WebServiceDemo
//
//  Created by Apple on 2021/7/29.
//

import Foundation
import YYModel

public class LXRequestResultContainer<T> where T: NSObject {
    public enum ResultType: Int {
        case originData
        case model
        case array
    }
    
    private var type: ResultType = ResultType.originData
    public var statuCode: String = ""
    public var dataModel: T = T.init()
    public var dataArray: [T] = []
    
    public var isValid: Bool = true
    
    public var originObject: Any? {
        didSet {
            decodeJSONObject()
        }
    }
    
    public var error: LXError?
    
    public var originData: Any?
    
    public init(jsonObject: Any, type: ResultType = ResultType.model) {
        self.originObject = jsonObject
        self.type = type
        decodeJSONObject()
    }
    
    private func setupDefaultErrorStatus() {
        statuCode = ""
        dataModel = T.init()
        dataArray = []
        isValid = false
        originData = nil
    }
    
    
    private func decodeJSONObject() {
        guard let jsonObject = self.originObject as? [String: Any] else {
            setupDefaultErrorStatus()
            self.error = LXError.serverDataFormatError
            return
        }
        
        guard let statuCode = jsonObject["code"] as? String else {
            setupDefaultErrorStatus()
            self.error = LXError.serverDataFormatError
            return
        }
        
        self.statuCode = statuCode
        
        if statuCode == ResponseCode.successResponseStatusCode {
            guard let data = jsonObject["data"] else {
                setupDefaultErrorStatus()
                self.error = LXError.missDataContent
                return
            }
            
            self.originData = data
            
            switch self.type {
            case .originData:
                break
            case .model:
                guard let dataDic = data as? [String: Any],
                      let model = T.yy_model(with: dataDic) else {
                    setupDefaultErrorStatus()
                    self.error = LXError.dataContentTransformToModelFailed
                    return
                }
                
                self.dataModel = model
                break
                
            case .array:
                guard let tempDataArray = data as? [[String: Any]] else {
                    setupDefaultErrorStatus()
                    self.error = LXError.dataContentTransfromToModelArrayFailed
                    return
                }
                
                self.dataArray = tempDataArray.map({ dic in
                    return T.yy_model(with: dic)!
                })
                
                break
            }
        } else {
            setupDefaultErrorStatus()
            self.error = LXError.serverResponseError(message: jsonObject["message"] as? String, code: statuCode)
        }
    }
}
