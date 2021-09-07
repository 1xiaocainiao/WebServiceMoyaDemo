//
//  TestModel.swift
//  WebServiceMoyaDemo
//
//  Created by xxf on 2021/7/30.
//

import UIKit
import YYModel

@objcMembers
class TestModel: LXBaseModel {
    var user_info: UserInfo?
    var site: SiteModel?
}

@objcMembers
class UserInfo: LXBaseModel {
    var username: String = ""
    var truename: String = ""
    var city: String = ""
    var age: String = ""
    var sex: String = ""
    var school: String = ""
}

@objcMembers
class SiteModel: LXBaseModel {
    var name: String = ""
    var url: String = ""
}
