//
//  TestPolicyApi.swift
//  WebServiceMoyaDemo
//
//  Created by xxf on 2021/8/1.
//

import Foundation
import Moya
import YYModel

@objcMembers
class PolicyParamModel: NSObject {
    var tapit_interval: String = ""
    var tapit_cout_per_time: String = ""
    var list_limit: String = ""
    var tapit_skim_through_times_new: String = ""
    var tapit_skim_through_times_old: String = ""
    var tapit_skim_through_times_vip: String = ""
    var is_open_five_star_pass: String = ""
}

enum PolicyEnum {
    case policy
}

extension PolicyEnum: TargetType, MoyaAddable {
    
    var task: Task {
        switch self {
        case .policy:
            let params = ["bundle_name": "", "api_name": ""]
            return .requestParameters(parameters: params.merged(with: self.publicParams()), encoding: URLEncoding.default)
        }
    }
}

enum TestRequestType {
    case baidu
    case upload([LXUploadFileInfo],[String: Any]? = nil)
}

extension TestRequestType: TargetType, MoyaAddable {
    var task: Task {
        switch self {
        case .baidu:
            let params = ["username": "postman", "password": "123465"]
            return .requestParameters(parameters: params.merged(with: self.publicParams()), encoding: URLEncoding.default)
            
        case .upload(let uploadFiles, let params):
            let formDatas = self.uploadFiles(files: uploadFiles, params: params)
            return .uploadMultipart(formDatas)
        }
    }
}
