//
//  MoyaTargetEx.swift
//  WebServiceDemo
//
//  Created by Apple on 2021/7/29.
//

import Moya

protocol MoyaAddable {
    
}

public extension TargetType {
    var baseURL : URL {
        return URL(string: "base url")!
    }
    
    var headers : [String : String]? {
        return nil
    }
}
