//
//  ViewController.swift
//  WebServiceMoyaDemo
//
//  Created by Apple on 2021/7/29.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        LXWebServiceHelper<PolicyParamModel>().requestJSONModel(PolicyEnum.policy) { container in
            print(container.dataModel)
        } exceptionHandle: { error in
            print(error)
        }


        // Do any additional setup after loading the view.
    }


}

