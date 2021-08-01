//
//  MoyaTargetEx.swift
//  WebServiceDemo
//
//  Created by Apple on 2021/7/29.
//

import Moya

let interface_version = ""

public protocol MoyaAddable {
    
}

public extension TargetType {
    var baseURL : URL {
        return URL(string: "")!
    }
    
    var path: String {
        return ""
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var headers : [String : String]? {
        return nil
    }
    
    var sampleData: Data {
        return "".data(using: String.Encoding.utf8)!
    }
}

public extension MoyaAddable {
    func publicParams() -> [String: String] {
        var resultInfo = [String: String]()
//        resultInfo["client_platform"] = "iOS"
//        resultInfo["client_os_version"] = UIDevice.current.systemVersion
//        resultInfo["client_app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
//        resultInfo[""] = ""
//        resultInfo[""] = ""
//        resultInfo[""] = ""
//        resultInfo["interface_version"] = interface_version
        
        resultInfo["client_platform"] = "iOS"
        resultInfo["client_os_version"] = UIDevice.current.systemVersion
        resultInfo["interface_version"] = "V475"
        resultInfo["client_app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        resultInfo["udid"] = "lsdfljasljdfljasldjfjlsdkjfkljlasjdf"
        resultInfo["device_type"] = "iPhone"
        return resultInfo
    }
    
    func uploadFiles(files: [LXUploadFileInfo]) -> [MultipartFormData] {
        let formDatas = files.map { fileInfo in
            return MultipartFormData(provider:
                                        .file(URL(fileURLWithPath: fileInfo.filePath)),
                                     name: fileInfo.fileUploadKey,
                                     fileName: fileInfo.fileName)
        }
        return formDatas
    }
}

public extension Dictionary {
    mutating func merge<S: Sequence>(conentOf other: S) where S.Iterator.Element == (key: Key, value: Value) {
        for (key, value) in other {
            self[key] = value
        }
    }
    
    func merged<S: Sequence>(with other: S) -> [Key: Value] where S.Iterator.Element == (key: Key, value: Value) {
        var dic = self
        dic.merge(conentOf: other)
        return dic
    }
}
