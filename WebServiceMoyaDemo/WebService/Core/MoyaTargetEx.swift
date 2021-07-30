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
        return URL(string: "https://www.baidufe.com/test-post.php")!
    }
    
    var headers : [String : String]? {
        return nil
    }
    
    var sampleData: Data {
        return "".data(using: String.Encoding.utf8)!
    }
}
