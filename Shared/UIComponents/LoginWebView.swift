//
//  LoginWebView.swift
//  AU COVID Cert (iOS)
//
//  Created by Richard Nelson on 15/9/21.
//

import Foundation
import SwiftUI
import Combine
import WebKit

struct SAWebView: View {
    var completionHandler: (_ success: Bool) -> Void
    var body: some View {
        LoginWebView() { success in
            completionHandler(success)
        }
    }
}

struct LoginWebView: UIViewRepresentable {
    
    var navigationHelper = WebViewHelper()
    var completionHandler: (_ success: Bool) -> Void

    init(completionHandler: @escaping (_ success: Bool) -> Void) {
        self.completionHandler = completionHandler
    }

    func makeUIView(context: UIViewRepresentableContext<LoginWebView>) -> WKWebView {
        let webview = WKWebView()
        webview.navigationDelegate = navigationHelper
        navigationHelper.completeHandler = { success in
            completionHandler(success)
        }
        if let _ = UserDefaults.standard.string(forKey: "refresh_token") {
            navigationHelper.doOauth(webView: webview)
        } else {
            let loginUrl = URL(string: "https://auth.my.gov.au/mga/sps/oauth/oauth20/authorize?response_type=code&client_id=wMm0AZnbwHYwKc1njWUF&state=007dc45f40b987d733c42ca4b08f98127f4fc100&scope=register&redirect_uri=au.gov.my.medicare:/oidcclient/redirect_uri&device_name=Richard%E2%80%99s%20iPhone%20XS%20Max&device_type=iPhone")!
            let request = URLRequest(url: loginUrl, cachePolicy: .returnCacheDataElseLoad)
            webview.load(request)
        }

        return webview
    }

    func updateUIView(_ webview: WKWebView, context: UIViewRepresentableContext<LoginWebView>) {
    }
}

extension URL {
    func containsParameter(name: String) -> Bool {
        let a = URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems?.filter { queryItem in
            queryItem.name == name
        }
        return a?.count ?? 0 > 0
    }
    func getParameterValue(name: String) -> String? {
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems?.filter { queryItem in
            queryItem.name == name
        }.first?.value
    }
}

struct TokenResponse: Codable { // or Decodable
    let access_token: String
    let refresh_token: String
}

class WebViewHelper: NSObject, WKNavigationDelegate, ObservableObject {
    private var loggedIn = false
    var completeHandler: ((_ success: Bool) -> Void)?
    
    func doOauth(webView: WKWebView) {
        let refreshToken = UserDefaults.standard.string(forKey: "refresh_token")
        guard let refreshToken = refreshToken else { return }
        var request = URLRequest(url: URL(string: "https://auth.my.gov.au/mga/sps/oauth/oauth20/token")!)
        request.httpMethod = "POST"
        request.addValue("Medicare/2 CFNetwork/1240.0.4 Darwin/20.6.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = "refresh_token=\(refreshToken)&client_id=wMm0AZnbwHYwKc1njWUF&redirect_uri=au.gov.my.medicare:/oidcclient/redirect_uri&grant_type=refresh_token".data(using: .utf8)
        doOauth(request, webView: webView)
    }
    
    func doOauth(_ request: URLRequest, webView: WKWebView) {
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data else { return }
            do {
                let res = try JSONDecoder().decode(TokenResponse.self, from: data)
                HTTPCookieStorage.shared.removeCookies(since: Date(timeIntervalSince1970: 0))
                DispatchQueue.main.async { [weak webView] in
                    webView?.configuration.websiteDataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0)) {
                        webView?.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Medicare 4.3.2"
                        UserDefaults.standard.set(res.refresh_token, forKey: "refresh_token")
                        UserDefaults.standard.set(res.access_token, forKey: "access_token")
                        var kickoffRequest = URLRequest(url: URL(string: "https://www2.medicareaustralia.gov.au/moasso/sps/oidc/rp/moa/kickoff/mobile")!)
                        kickoffRequest.addValue("Bearer \(res.access_token)", forHTTPHeaderField: "Authorization")
                        kickoffRequest.addValue("APP", forHTTPHeaderField: "route")
                        kickoffRequest.addValue("EXPIOS", forHTTPHeaderField: "device-type")
                        kickoffRequest.addValue("", forHTTPHeaderField: "Cookie")
                        webView!.load(kickoffRequest)
                    }
                }
            } catch {
                return
            }
            
        }.resume()
    }
    func doOauth(code: String, webView: WKWebView) {
        var request = URLRequest(url: URL(string: "https://auth.my.gov.au/mga/sps/oauth/oauth20/token")!)
        request.httpMethod = "POST"
        request.httpBody = "code=\(code)&client_id=wMm0AZnbwHYwKc1njWUF&redirect_uri=au.gov.my.medicare:/oidcclient/redirect_uri&grant_type=authorization_code".data(using: .utf8)
        doOauth(request, webView: webView)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if (url.getParameterValue(name: "_eventId") == "close") { // The close button in the top right
                decisionHandler(.cancel)
                completeHandler?(false)
                return
            }
            if url.scheme == "au.gov.my.medicare" {
                if (url.containsParameter(name: "code")) {
                    guard let code = url.getParameterValue(name: "code") else {
                        decisionHandler(.cancel)
                        return
                    }
                    doOauth(code: code, webView: webView)
                } else if (url.path.contains("login_success")) {
                    // TODO: Try waiting here and loading member list directly
                    let request = URLRequest(url: URL(string: "https://www2.medicareaustralia.gov.au/moaonline/")!)
                    webView.load(request)
                    loggedIn = true
                    /*URLSession.shared.dataTask(with: request) {(data, response, error) in
                        print("got list")
                    }.resume()*/
                }
                decisionHandler(.cancel)
                return
            } else {
                if (navigationAction.request.value(forHTTPHeaderField: "Authorization") != nil) {
                    decisionHandler(.allow)
                    return
                } else {
                    guard let url = navigationAction.request.url,
                          navigationAction.request.httpMethod == "GET",
                          let access_token = UserDefaults.standard.string(forKey: "access_token")
                          else {
                        decisionHandler(.allow)
                        return
                    }
                    let newRequest = NSMutableURLRequest(url: url)
                    newRequest.setValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
                    webView.load(newRequest as URLRequest)
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if (loggedIn) {
            sleep(2)
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                cookies.forEach { cookie in
                    if (cookie.domain.contains("medicareaustralia.gov.au") && (
                        cookie.path == "/" || cookie.path == "/moaapi")) {
                        HTTPCookieStorage.shared.setCookie(cookie)
                        let newCookie = HTTPCookie(properties: [
                            .domain: "medicare.whatsbeef.net",
                            .name: cookie.name,
                            .value: cookie.value,
                            .path: "/",
                            .secure: cookie.isSecure
                        ])
                        if let newCookie = newCookie {
                            HTTPCookieStorage.shared.setCookie(newCookie)
                            //URLSession.shared.configuration.httpCookieStorage?.setCookie(newCookie)
                            print("set cookie \(newCookie.name): \(newCookie.value)")
                        }
                    }
                }
                self.completeHandler?(true)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("didStartProvisionalNavigation")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("didFailProvisionalNavigation")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("webviewDidCommit")
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("didReceiveAuthenticationChallenge")
        completionHandler(.performDefaultHandling, nil)
    }
}
