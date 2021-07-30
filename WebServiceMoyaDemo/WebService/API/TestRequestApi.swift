//
//  TestApi.swift
//  WebServiceDemo
//
//  Created by Apple on 2021/7/29.
//

import Moya

enum DouBan {
    case channels
    case playlist(String)
}

extension DouBan: TargetType {
    var path: String {
        switch self {
        case .channels:
            return "/j/app/radio/channels"
        case .playlist(_):
            return "/j/mine/playlis"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var sampleData: Data {
        return "".data(using: String.Encoding.utf8)!
    }
    
    var task: Task {
        switch self {
        case .playlist(let channel):
            var params: [String: Any] = [:]
            params["channel"] = channel
            params["type"] = "n"
            params["from"] = "mainsite"
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        default:
            return .requestPlain
        }
    }
}

/// 分割线



enum TestRequestType {
    case baidu
    case upload([LXUploadFileInfo])
}

extension TestRequestType: TargetType, MoyaAddable {
    var path: String {
        return ""
    }
    
    var task: Task {
        switch self {
        case .baidu:
            let params = ["username": "postman", "password": "123465"]
            return .requestParameters(parameters: params.merged(with: self.publicParams()), encoding: URLEncoding.default)
            
        case .upload(let uploadFiles):
            let formDatas = self.uploadFiles(files: uploadFiles)
            return .uploadMultipart(formDatas)
        }
    }
}
