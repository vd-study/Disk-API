//
//  AuthViewController.swift
//  yandexdisk
//
//  Created by Vlad on 30/07/2019.
//  Copyright © 2019 Anatoly. All rights reserved.
//

import Foundation
import WebKit
import Alamofire

protocol AuthViewControllerDelegate: class {
    func handleTokenChanged(token: String)
}

final class AuthViewController: UIViewController {
    
    weak var delegate: AuthViewControllerDelegate?
    
    private let webView = WKWebView()
    private let clientId = "49ec09cb4a4d4ab38aa120ac5d8f6271" // здесь должен быть ID вашего зарегистрированного приложения
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        guard let request = tokenGetRequest else { return }
        webView.load(request)
        webView.navigationDelegate = self
    }
    
    // MARK: Private
    private func setupViews() {
        view.backgroundColor = .white
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }
    
    private var tokenGetRequest: URLRequest? {
        
        let parameters: Parameters = ["response_type": "token", "client_id": "\(clientId)"]
        
        let task = Alamofire.request("https://oauth.yandex.ru/authorize",
                          method: .get,
                          parameters: parameters)
        guard let url = task.request?.url else { return nil }
        
        return URLRequest(url: url)
    }
}

extension AuthViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.scheme == scheme {
            let targetString = url.absoluteString.replacingOccurrences(of: "#", with: "?")
            // You can do without Alamofire
            guard let components = URLComponents(string: targetString) else { return }
            
            if let token = components.queryItems?.first(where: { $0.name == "access_token" })?.value {
                delegate?.handleTokenChanged(token: token)
            }
            
            dismiss(animated: true, completion: nil)
        }
        defer {
            decisionHandler(.allow)
        }
    }
}

private let scheme = "myphotos" // схема для callback
