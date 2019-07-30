//
//  ViewController.swift
//  yandexdisk
//
//  Created by Vlad on 30/07/2019.
//  Copyright © 2019 Anatoly. All rights reserved.
//

import UIKit
import Alamofire

final class ViewController: UIViewController {
    
    private let tableView = UITableView()
    private let textField = UITextField()
    private let uploadButton = UIButton()
    
    private var token: String = ""
    
    private var filesData: DiskResponse?
    
    private var first = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround() //Use a hide keyboard method
        setupViews() // Design in code
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if first {
            updateData()
        }
        first = false
    }
    // MARK: Private
    private func setupViews() {
        view.backgroundColor = .white
        
        title = "Мои фото"
        
        tableView.register(FileTableViewCell.self, forCellReuseIdentifier: fileCellIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.dataSource = self
        
        //link in yandex picture
        textField.text = "https://avatars.mds.yandex.net/get-pdb/49816/c6157607-097b-4e75-a8ad-a3beca70f641/s800"
        
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textFieldHeight))
        textField.leftViewMode = .always
        textField.backgroundColor = UIColor.gray.withAlphaComponent(0.1)
        textField.placeholder = "Введите URL за загрузки файла"
        
        uploadButton.setTitle("↓", for: .normal)
        uploadButton.setTitleColor(.black, for: .normal)
        uploadButton.addTarget(self, action: #selector(uploadFile), for: .touchUpInside)
        
        [tableView, textField, uploadButton].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(updateData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textField.heightAnchor.constraint(equalToConstant: textFieldHeight),
            
            uploadButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            uploadButton.heightAnchor.constraint(equalTo: textField.heightAnchor),
            uploadButton.widthAnchor.constraint(equalTo: uploadButton.heightAnchor),
            uploadButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor),
            uploadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: textField.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
    }
    
    private func requestToken() {
        let requestTokenViewController = AuthViewController()
        requestTokenViewController.delegate = self
        present(requestTokenViewController, animated: false, completion: nil)
    }
    private func giveHeaders() -> HTTPHeaders {
        let headers: HTTPHeaders = [
            "Authorization": "OAuth \(token)",
            "Accept": "application/json"
        ]
        return headers
    }
    
    @objc
    private func updateData() {
        guard !token.isEmpty else {
            requestToken()
            return
        }
        
        let parameters: Parameters = ["media_type": "image"]
        
        Alamofire.request(diskAPI,
                          method: .get,
                          parameters: parameters ,
                          headers: giveHeaders())
            .responseJSON{ response in
            
            if let _ = response.result.value {
                guard let data = response.data else {return}
                guard let newFiles = try? JSONDecoder().decode(DiskResponse.self, from: data) else { return }
                print("Received \(newFiles.items?.count ?? 0) files")
                self.filesData = newFiles
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
                
            } else {
                print(response.error?.localizedDescription ?? "Response have a error.")
            }
            
        }
    }
    
    @objc private func uploadFile() {
        
        guard let fileUrl = textField.text, !fileUrl.isEmpty else { return }
        
        let fullNameArr = fileUrl.components(separatedBy: "/") // get special name from new picture
        
        let parameters: Parameters = ["url": fileUrl , "path": fullNameArr[fullNameArr.count - 3]]
        
        Alamofire.request("https://cloud-api.yandex.net/v1/disk/resources/upload",
                          method: .post,
                          parameters: parameters,
                          encoding: URLEncoding.queryString,
                          headers: giveHeaders()).validate().responseJSON { response in
                            switch response.result {
                            case .success:
                                print("File added in Disk!")
                            case .failure(let error):
                                print(error.localizedDescription)
                            }
        }
    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: fileCellIdentifier, for: indexPath)
        guard let items = filesData?.items, items.count > indexPath.row else {
            return cell
        }
        let currentFile = items[indexPath.row]
        if let fileCell = cell as? FileTableViewCell {
            fileCell.delegate = self
            fileCell.bindModel(currentFile)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filesData?.items?.count ?? 0
    }
}

extension ViewController: AuthViewControllerDelegate {
    func handleTokenChanged(token: String) {
        self.token = token
        updateData()
    }
    
    //Hide a keyboard method
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension ViewController: FileTableViewCellDelegate {
    
    func loadImage(stringUrl: String, completion: @escaping ((UIImage?) -> Void)) {
        
        guard let _ = URL(string: stringUrl) else { return }
        
        Alamofire.request(stringUrl,
                          method: .get,
                          headers: giveHeaders()).responseData { response in
            guard let data = response.result.value else { return }
            let image = UIImage(data: data)
            completion(image)
        }
    }
}

private let diskAPI = "https://cloud-api.yandex.net/v1/disk/resources/files"
private let fileCellIdentifier = "FileTableViewCell"
private let textFieldHeight: CGFloat = 44
