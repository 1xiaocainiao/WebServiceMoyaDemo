//
//  MoyaTargetEx.swift
//  WebServiceDemo
//
//  Created by Apple on 2021/7/29.
//

import Moya

let interface_version = ""

public struct LXMoyaLoadStatus {
    var isRefresh: Bool
    var needLoadDBWhenRefreshing: Bool
    var needCache: Bool
    var clearDataWhenCache: Bool
    
    init(isRefresh: Bool = false,
         needLoadDBWhenRefreshing: Bool = false,
         needCache: Bool = false,
         clearDataWhenCache: Bool = false) {
        self.isRefresh = isRefresh
        self.needLoadDBWhenRefreshing = needLoadDBWhenRefreshing
        self.needCache = needCache
        self.clearDataWhenCache = clearDataWhenCache
    }
}

public protocol MoyaAddable {
    var cacheKey: String { get }
    
    var loadingStatus: LXMoyaLoadStatus { get }
}

public extension MoyaAddable {
    var cacheKey: String {
        return "cacheKey"
    }
    
    var loadingStatus: LXMoyaLoadStatus {
        return LXMoyaLoadStatus()
    }
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
    
    func uploadFiles(files: [LXUploadFileInfo], params: [String: Any]?) -> [MultipartFormData] {
        var formDatas = files.map { fileInfo in
            return MultipartFormData(provider:
                                        .file(URL(fileURLWithPath: fileInfo.filePath)),
                                     name: fileInfo.fileUploadKey,
                                     fileName: fileInfo.fileName)
        }
        
        if let params = params,
           let paramsData = paramsEncrypt(params: params.merged(with: publicParams())) {
            let dicData = MultipartFormData(provider: .data(paramsData), name: "data")
            formDatas.append(dicData)
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
