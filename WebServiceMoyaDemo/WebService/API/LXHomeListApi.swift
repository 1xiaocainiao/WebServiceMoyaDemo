

import Foundation
import Moya

enum LXHomeListApi {
    case type(String, page: Int = 1)
}

extension LXHomeListApi: TargetType, MoyaAddable {
    var path: String {
        return "/app-middleground/app-user/rank/findList"
    }
    
    var task: Task {
        switch self {
        case .type(let type, page: let page):
            return .requestParameters(parameters: ["type": type, "lng": "12.1","lat": "12.1", "page": page, "size": "10"].merged(with: publicParams()), encoding: URLEncoding.default)
        }
    }
    
    func loadListStatus() -> LXMoyaLoadListStatus {
        switch self {
        case .type(_, page: let page):
            return LXMoyaLoadListStatus(isRefresh: page == 1, needLoadDBWhenRefreshing: page == 1, needCache: page == 1)
        }
    }
    
    var cacheKey: String {
        switch self {
        case .type(let type, page:  _):
            return "homeList\(type)"
        }
    }
}
