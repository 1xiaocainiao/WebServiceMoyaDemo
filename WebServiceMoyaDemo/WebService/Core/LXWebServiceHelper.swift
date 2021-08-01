//
//  LXWebServiceHelper.swift
//  WebServiceDemo
//
//  Created by Apple on 2021/7/29.
//

import Foundation
import Moya
import YYModel

open class LXWebServiceHelper<T> where T: NSObject {
    
    typealias JSONObjectHandle = (Any) -> Void
    typealias ExceptionHandle = (Error?) -> Void
    typealias ResultContainerHandle = (LXRequestResultContainer<T>) -> Void
    
    
    @discardableResult
    func requestJSONObject<R: TargetType & MoyaAddable>(_ type: R,
                                              progressBlock: ProgressBlock? = nil,
                                              completionHandle: @escaping JSONObjectHandle, exceptionHandle: @escaping ExceptionHandle) -> Cancellable? {
        return _WebServiceHelper.default.requestJSONObject(type,
                                                           progressBlock: progressBlock, completionHandle: completionHandle, exceptionHandle: exceptionHandle)
    }
    
    @discardableResult
    func requestJSONModel<R: TargetType & MoyaAddable>(_ type: R,
                                                   progressBlock: ProgressBlock? = nil,
                                                   completionHandle: @escaping ResultContainerHandle, exceptionHandle: @escaping ExceptionHandle) -> Cancellable? {
        return _WebServiceHelper.default.requestJSONObject(type, progressBlock: progressBlock) { result in
            let container = LXRequestResultContainer<T>.init(jsonObject: result, type: .model)
            if container.isValid {
                completionHandle(container)
            } else {
                exceptionHandle(container.error)
            }
        } exceptionHandle: { error in
            exceptionHandle(error)
        }
    }
    
    @discardableResult
    func requestJSONModelArray<R: TargetType & MoyaAddable>(_ type: R,
                                                        progressBlock: ProgressBlock? = nil,
                                                        completionHandle: @escaping ResultContainerHandle, exceptionHandle: @escaping ExceptionHandle) -> Cancellable? {
        return _WebServiceHelper.default.requestJSONObject(type, progressBlock: progressBlock) { result in
            let container = LXRequestResultContainer<T>.init(jsonObject: result, type: .array)
            if container.isValid {
                completionHandle(container)
            } else {
                exceptionHandle(container.error)
            }
        } exceptionHandle: { error in
            exceptionHandle(error)
        }
    }
}

fileprivate class _WebServiceHelper {
    static let `default` = _WebServiceHelper()
    
    // 可自定义加解密插件等
    private func createProvider<R: TargetType & MoyaAddable>(type: R) -> MoyaProvider<R> {
        let activityPlugin = NetworkActivityPlugin { state, targetType in
            self.networkActiviyIndicatorVisible(visibile: state == .began)
        }
        
        let aesPlugin = LXAESPlugin()
        
        let provider = MoyaProvider<R>(plugins: [activityPlugin, aesPlugin])
        
        return provider
    }
    
    private func networkActiviyIndicatorVisible(visibile: Bool) {
        if #available(iOS 13, *) {
            
        } else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = visibile
        }
    }
    
    @discardableResult
    func requestJSONObject<R: TargetType & MoyaAddable>(_ type: R,
                                                        progressBlock: ProgressBlock?,
                                                        completionHandle: @escaping LXWebServiceHelper<NSObject>.JSONObjectHandle, exceptionHandle: @escaping (Error?) -> Void) -> Cancellable? {
        let provider = createProvider(type: type)
        let cancelable = provider.request(type, callbackQueue: nil, progress: progressBlock) { result in
            switch result {
            case .success(let successResponse):
                do {
                    let option = JSONSerialization.ReadingOptions.allowFragments
                    let jsonObject = try JSONSerialization.jsonObject(with: successResponse.data, options: option)
                    
                    print(jsonObject)
                    
                    let container = LXRequestResultContainer<NSObject>(jsonObject: jsonObject, type: .originData)
                    if container.isValid {
                        completionHandle(jsonObject)
                    } else {
                        exceptionHandle(container.error)
                    }
                } catch  {
                    exceptionHandle(LXError.serverDataFormatError)
                }
                break
            case .failure(_):
                exceptionHandle(LXError.networkConnectFailed)
                break
            }
        }
        return cancelable
    }
}
