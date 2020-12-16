//
//  GoogleLoginHandler.swift
//
//
//  Created by Shubham on 13/11/20.
//

import Foundation
import PromiseKit

class FacebookLoginHandler: AbstractLoginHandler{
    let loginType: SubVerifierType
    let clientID: String
    let redirectURL: String
    let browserRedirectURL: String?
    let nonce = String.randomString(length: 10)
    let state: String
    var userInfo: [String: Any]?
    let extraQueryParams: [String: String]
    let defaultParams: [String:String] = ["scope": "public_profile email", "response_type": "token"]
    
    public init(loginType: SubVerifierType = .web, clientID: String, redirectURL: String, browserRedirectURL: String?, extraQueryParams: [String: String] = [:]){
        self.loginType = loginType
        self.clientID = clientID
        self.redirectURL = redirectURL
        self.extraQueryParams = extraQueryParams
        self.browserRedirectURL = browserRedirectURL
        
        let tempState = ["nonce": self.nonce, "redirectUri": self.redirectURL, "redirectToAndroid": "true"]
        let jsonData = try! JSONSerialization.data(withJSONObject: tempState, options: .prettyPrinted)
        self.state =  String(data: jsonData, encoding: .utf8)!.toBase64URL()
    }
    
    func getUserInfo(responseParameters: [String : String]) -> Promise<[String : Any]> {
        return self.handleLogin(responseParameters: responseParameters)
    }
    
    func getLoginURL() -> String{
        // left join
        var tempParams = self.defaultParams
        tempParams.merge(["redirect_uri": self.redirectURL, "client_id": self.clientID, "state": self.state]){(_, new ) in new}
        tempParams.merge(self.extraQueryParams){(_, new ) in new}
        
        // Reconstruct URL
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "www.facebook.com"
        urlComponents.path = "v6.0/dialog/oauth"
        urlComponents.setQueryItems(with: tempParams)
        
        return urlComponents.url!.absoluteString
        //       return "https://www.facebook.com/v6.0/dialog/oauth?response_type=token&client_id=\(self.clientId)" + "&state=random&scope=public_profile email&redirect_uri=\(newRedirectURL)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
    
    func getVerifierFromUserInfo() -> String {
        return self.userInfo!["id"] as! String
    }
    
    func handleLogin(responseParameters: [String : String]) -> Promise<[String : Any]> {
        let (tempPromise, seal) = Promise<[String:Any]>.pending()
        
        if let accessToken = responseParameters["access_token"]{
            var request = makeUrlRequest(url: "https://graph.facebook.com/me?fields=name,email,picture.type(large)", method: "GET")
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(.promise, with: request).map{
                try JSONSerialization.jsonObject(with: $0.data) as! [String:Any]
            }.done{ data in
                var json = data
                self.userInfo = data
                json["tokenForKeys"] = accessToken
                json["verifierId"] = self.getVerifierFromUserInfo()
                seal.fulfill(json)
                
            }.catch{err in
                seal.reject(TSDSError.getUserInfoFailed)
            }
        }else{
            seal.reject(TSDSError.accessTokenNotProvided)
        }
        
        return tempPromise
    }
    
    
}
