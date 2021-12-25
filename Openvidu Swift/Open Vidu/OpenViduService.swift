//
//  OpenViduService.swift
//  WebRTCapp
//
//  Created by Dario Pacchi on 16/06/2020.
//  Copyright © 2020 Sergio Paniego Blanco. All rights reserved.
//

import Foundation
import UIKit

class OpenViduService: UIViewController, URLSessionDelegate {
    
    static let shared = OpenViduService()
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.host == "videoconference.samt.bankmellat.ir" {
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    func connectTo(url : String, username: String, password: String, room: String, completion: @escaping (_ token: OpenViduToken?, _ success: Bool, _ error: Error? ) -> Void) {
//    func connectTo(url : String, username: String, password: String, room: String, completion: @escaping (_ token: String?, _ success: Bool, _ error: Error? ) -> Void) {
        
        getRoom(url: url, username: username, password: password, room: room) {[weak self] (success, error, sessionId) in
            
            guard success == true else {
                completion(nil,false,error)
                return
            }
            
            self?.getToken(url: url, username: username, password: password, room: sessionId) { (token, success, error) in
                guard success == true else {
                    completion(nil,false,error)
                    return
                }
                
                completion(token,true,error)
            }
        }
    }
    
    func basicTokenFor(username: String, password: String) -> String {
        
        let bearer = "\(username):\(password)"
        return "Basic \(bearer.toBase64())"
    }
    
    private func getRoom(url : String, username: String, password: String, room: String, completion: @escaping (_ success: Bool, _ error: Error?, _ sessionId: String) -> Void) {
        
        let bearer = basicTokenFor(username: username, password: password)
        
        let uri = URL(string: url.appending("/sessions/"))!
        var request = URLRequest(url: uri)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(bearer, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        let json = "{\"customSessionId\": \"\(room)\"}"
        request.httpBody = json.data(using: .utf8)
        
        var responseString = ""
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue?.none)
        let task = session.dataTask(with: request) { data, response, error in
            
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("⚠️ [OpenVidu] error=\(String(describing: error)), Status Code: \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                completion(false, error, room)
                return
            }
            guard let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 200 else {           // check for http errors
                print("⚠️ [OpenVidu] error=\(String(describing: error)), Status Code: \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                completion(true, error, room)
                return
            }
            responseString = String(data: data, encoding: .utf8)!
            print("[OpenVidu] \(responseString)")
            
            let jsonData = responseString.data(using: .utf8)!
            var sessionId = room
            do {
                let json = try JSONSerialization.jsonObject(with: jsonData, options : .allowFragments) as? Dictionary<String,Any>
                sessionId = json!["id"] as! String
            } catch let error as NSError {
                print(error)
            }
            completion(true,nil,sessionId)
        }
        task.resume()
    }
    
    private func getToken(url : String, username: String, password: String, room: String, completion: @escaping (_ token: OpenViduToken?, _ success: Bool, _ error: Error? ) -> Void) {
//    private func getToken(url : String, username: String, password: String, room: String, completion: @escaping (_ token: String?, _ success: Bool, _ error: Error? ) -> Void) {
        
        let bearer = basicTokenFor(username: username, password: password)
        
        let uri = URL(string: url.appending("/tokens/"))!
//        let uri = URL(string: "https://demos.openvidu.io/openvidu/api/sessions/SessionB/connection")!
        var request = URLRequest(url: uri)
//        var openViduSecret = "Vh67#9847hg#K"
//        openViduSecret = "OPENVIDUAPP:" + openViduSecret
//        let authHeader = openViduSecret.data(using: .utf8)
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("Basic \(authHeader?.base64EncodedString() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(bearer, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        let json = "{\"session\": \"" + room + "\"}"
        request.httpBody = json.data(using: .utf8)
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue?.none)
        let task = session.dataTask(with: request) { data, response, error in
            
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("⚠️ [OpenVidu] error=\(String(describing: error)), Status Code: \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                completion(nil, false, error)
                return
            }
            guard let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 200 else {           // check for http errors
                print("⚠️ [OpenVidu] error=\(String(describing: error)), Status Code: \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                completion(nil, false, error)
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
            let token = try? JSONDecoder().decode(OpenViduToken.self, from: data) as OpenViduToken
//            let jsonData = responseString?.data(using: .utf8)!
//            var token: String = ""
//            do {
//                let jsonArray = try JSONSerialization.jsonObject(with: jsonData!, options : .allowFragments) as? Dictionary<String,Any>
//                if jsonArray?["token"] != nil {
//                    print("response someKey exists")
//                    token = jsonArray?["token"] as! String
//                } else {
////                            token = "wss://192.168.0.106:4443?sessionId=SessionA&token=6m6xfsbfvme5rhek"
////                            &role=PUBLISHER&version=2.12.0&coturnIp=172.18.138.82&turnUsername=HEVWW1&turnCredential=lxdqhm\
//                }
//            } catch let error as NSError {
//                print(error)
//            }
            completion(token, true, error)
        }
//        {\"id\":\"con_QVySek9nbr\",\"object\":\"connection\",\"status\":\"pending\",\"connectionId\":\"con_QVySek9nbr\",\"sessionId\":\"SessionB\",\"createdAt\":1636364454711,\"type\":\"WEBRTC\",\"record\":true,\"role\":\"PUBLISHER\",\"kurentoOptions\":null,\"rtspUri\":null,\"adaptativeBitrate\":null,\"onlyPlayWithSubscribers\":null,\"networkCache\":null,\"serverData\":\"\",\"token\":\"wss://demos.openvidu.io?sessionId=SessionB&token=tok_I75niKBQOR8ByvZT&webrtcStatsInterval=30&sendBrowserLogs=debug_app\",\"activeAt\":null,\"location\":null,\"ip\":null,\"platform\":null,\"clientData\":null,\"publishers\":null,\"subscribers\":null}
        task.resume()
    }
}

extension String {

    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }

}

// MARK: - OpenViduToken
struct OpenViduToken: Codable {
    let id, session, role, data: String
    let token: String
    
    func getJustSessionId() -> String {
        return token.slice(from: "sessionId=", to: "&") ?? ""
    }
    
    func getJustToken() -> String {
        return token.slice(from: "&token=", to: "&") ?? ""
    }
    
    func getQueryParameter(parameter : String) -> String {
        print("token att- \(token)")
        print("tok param- \(parameter)")
        if let value = token.slice(from: "&\(parameter)=", to: "&") {
            print("val1- \(value)")
            return value
        }
        print("val2- \(token.components(separatedBy: "\(parameter)=").last ?? "")")
        return token.components(separatedBy: "\(parameter)=").last ?? ""
    }
}

extension String {

    func slice(from: String, to: String) -> String? {

        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

