//
//  ViewController.swift
//  googleSuggestAPISample
//
//  Created by anies1212 on 2022/04/07.
//

import UIKit
import BrightFutures

class ViewController: UIViewController {

    dynamic var suggestItems: [String] = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    var suggestedAutocompleteLists: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        print(#function)
        view.backgroundColor = .white
//        setupSearchBar()
//        setupTableView()
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        self.addObserver(self, forKeyPath: "suggestItems", options: NSKeyValueObservingOptions.new, context: nil)
        tableView.addObserver(self, forKeyPath: "contentSize", options: (NSKeyValueObservingOptions.new), context: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    deinit {
//        self.removeObserver(self, forKeyPath: "suggestItems")
//        tableView.removeObserver(self, forKeyPath: "contentSize")
    }
}

//MARK: - set up

//extension ViewController {
//
//    private func setupSearchBar() {
//        let searchBar: UISearchBar = UISearchBar(frame: .zero)
//        searchBar.delegate = self
//        searchBar.showsCancelButton = true
//        searchBar.keyboardAppearance = .dark
//        searchBar.keyboardType = .default
//        navigationItem.titleView = searchBar
//        navigationItem.titleView?.frame = searchBar.frame
//        self.searchBar = searchBar
//        searchBar.becomeFirstResponder()
//        view.addSubview(searchBar)
//    }
//
//    private func setupTableView() {
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.tableFooterView = UIView()
//        tableView.isHidden = true
////
        
//    }
//}

// MARK: - tableView height observer

extension ViewController {
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            didChangeTableViewContentHeight()
        } else if keyPath == "suggestItems" {
            didChangeSuggestItems()
        }
    }
    //
    //
    private func didChangeTableViewContentHeight() {
        print(#function)
        tableView.setNeedsLayout()
        tableView.setNeedsUpdateConstraints()
        UIView.animate(withDuration: 0.6, animations: {[weak self] () -> Void in
            self?.tableView.layoutIfNeeded()
        })
    }
    //
    private func didChangeSuggestItems() {
        DispatchQueue.main.async {[weak self] in
            self?.tableView.isHidden = false
            self?.tableView.reloadData()
        }
    }
}

// MARK: - tableview delegate

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - tableview dataSource

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let TableViewBasicCellIdentifier = "BasicCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewBasicCellIdentifier, for: indexPath)
//        cell.textLabel?.text = suggestItems[indexPath.row]
        cell.textLabel?.text = suggestedAutocompleteLists[indexPath.row]
        print("suggestedAutocompleteLists:\(suggestedAutocompleteLists)")
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestItems.count
    }
}

// MARK: - search bar delegate

extension ViewController: UISearchBarDelegate {

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print(#function)
        searchBar.resignFirstResponder()
        navigationController?.setNavigationBarHidden(true, animated: true)
        dismiss(animated: true, completion: nil)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(#function)
        print("searchText = \(searchText)")
        self.searchSuggestKeyword(keyword: searchText)
    }

}

// MARK: - search suggest keyword

extension ViewController {

    private func searchSuggestKeyword(keyword: String) {
        if keyword.count < 1 {
                return
            }
        futureSuggestRequest(searchKeywork:keyword).onSuccess { suggestItems in
                self.suggestItems = suggestItems
            }.onFailure { error in
                print("error = \(error)")
            }

        }

        private func futureSuggestRequest(searchKeywork: String) -> Future<[String],Error> {
            let promiss = Promise<[String],Error>()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let URL = self.createSuggestURL(_searchKeywoard: searchKeywork) {
                    let request = self.requestURL(URL: URL)
                    self.sendRequest(request: request).flatMap { data in
                        self.futureSuggestItems(_data: data)
                    }.onSuccess { suggestItems in
                        print("suggestItems:\(suggestItems)")
                        promiss.success(suggestItems)
                    }.onFailure { error in
                        promiss.failure(error)
                    }
                }
            }

            return promiss.future
        }

        private func sendRequest(request: URLRequest) -> Future<Data, Error> {
            let promiss = Promise<Data, Error>()
            let session = URLSession.shared
            let task = session.dataTask(with: request) { responseData, NSURLResponse, connectError in
                if let error = connectError {
                    promiss.failure(error)
                    print("failed to send request")
                } else {
                    promiss.success(responseData!)
                    print("responseData!:\(responseData!)")
                }
            }
            task.resume()
            return promiss.future
        }

    private func futureSuggestItems(_data: Data) -> Future<[String], Error> {
        let promiss = Promise<[String], Error>()
        let error: Error? = nil
        print("_data:\(_data)")
        if let dataString = String(data: _data, encoding: String.Encoding.shiftJIS) , let d = dataString.data(using: String.Encoding.utf8) {
            do {
                suggestItems = dataString.components(separatedBy: "[")
                suggestItems[2] = suggestItems[2].replacingOccurrences(of: "\"", with: "")
                suggestItems[2] = suggestItems[2].replacingOccurrences(of: "]", with: "")
                suggestItems[2] = String(suggestItems[2].dropLast())
                suggestItems = suggestItems[2].components(separatedBy: ",")
                print("typeOfDataString:\(type(of: dataString))")
                print("dataString:\(dataString)")
                print("d:\(d)")
                print("typeOfSuggestedAutocompleteLists:\(type(of: suggestedAutocompleteLists))")
                let newArray = suggestedAutocompleteLists.map {$0.utf8.count}
                print("newArray:\(newArray)")
                print("suggestItems:\(suggestItems)")
                if let jsonArray = try JSONSerialization.jsonObject(with: d, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String] {
                    let suggestItems = convertSuggestItems(jsonArray: jsonArray)
                    promiss.success(suggestItems)
                }
            } catch (let e) {
                promiss.failure(e)
            }
        } else {
            if let e = error {
                promiss.failure(e)
            }
        }
        return promiss.future
    }

    private func convertSuggestItems(jsonArray: [String]) -> [String] {
        var newSuggestWords: [String] = []
        print("jsonArrayConvert:\(jsonArray)")
        let strs = jsonArray.lastObject as? [String]
            for str in strs {
                newSuggestWords.append(str)
            }
        print("newSuggestWords:\(newSuggestWords)")
        return newSuggestWords
    }

        private func requestURL(URL: URL) -> URLRequest {
            var request = URLRequest(url: URL)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "GET"
            print("request:\(request)")
            return request
        }

    private func createSuggestURL(_searchKeywoard: String) -> URL? {
        if let percentageString = _searchKeywoard.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed){
            let urlString = "http://clients1.google.com/complete/search?hl=ja&ds=yt&client=firefox&q=\(percentageString)"
            print("urlString:\(urlString)")
            return URL(string: urlString)
        }
        return URL(string: "")
    }

}
