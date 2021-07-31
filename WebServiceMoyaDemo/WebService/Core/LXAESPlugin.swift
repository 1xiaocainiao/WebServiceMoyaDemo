//
//  LXAESPlugin.swift
//  WebServiceMoyaDemo
//
//  Created by xxf on 2021/7/31.
//

import Foundation
import Moya



class LXAESPlugin: PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request
        switch target.task {
        case .requestParameters(parameters: let params, encoding: _):
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: params,
                                                          options: JSONSerialization.WritingOptions.prettyPrinted)
                
                guard let encryptData = AES.default.encrypt(data: jsonData) else {
                    return request
                }
                
                request.setValue(kPublicKey, forHTTPHeaderField: "APPID")
                
                request.httpBody = encryptData.base64EncodedData()
            } catch  {
                debugPrint("encrypt failed")
            }
        default:
            return request
        }
        return request
    }
    
    func process(_ result: Result<Response, MoyaError>, target: TargetType) -> Result<Response, MoyaError> {
        switch result {
        case .success(let successReponse):
            guard let base64DecryptData = Data(base64Encoded: successReponse.data) else {
                return .failure(.parameterEncoding(LXError.serverDataFormatError))
            }
            
            guard let decryptData = AES.default.decrpty(data: base64DecryptData) else {
                return .failure(.parameterEncoding(LXError.serverDataFormatError))
            }
            
            return .success(Response(statusCode: successReponse.statusCode, data: decryptData))
        case .failure(let error):
            return .failure(error)
        }
    }
}
