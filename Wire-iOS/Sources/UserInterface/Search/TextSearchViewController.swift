//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import zmessaging
import ZMCDataModel
import Cartography


final internal class TextSearchViewController: UIViewController, TextSearchQueryDelegate {
    private var tableView: UITableView!
    private var searchBar: UISearchBar!
    
    public weak var delegate: MessageActionResponder? = .none
    public let conversation: ZMConversation
    public var searchQuery: String? {
        return self.searchBar.text
    }

    private var textSearchQuery: TextSearchQuery?
    
    fileprivate var results: [ZMConversationMessage] = []
    
    init(conversation: ZMConversation) {
        self.conversation = conversation
        super.init(nibName: .none, bundle: .none)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatal("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView = UITableView()
        self.tableView.register(TextSearchResultCell.self, forCellReuseIdentifier: TextSearchResultCell.reuseIdentifier)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 44
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .interactive
        
        self.view.addSubview(self.tableView)
        
        self.searchBar = UISearchBar()
        self.searchBar.delegate = self
        self.view.addSubview(self.searchBar)
        
        constrain(self.view, self.tableView, self.searchBar) { view, tableView, searchBar in
            searchBar.top == view.top
            searchBar.leading == view.leading
            searchBar.trailing == view.trailing
            
            tableView.top == searchBar.bottom
            
            tableView.leading == view.leading
            tableView.trailing == view.trailing
            tableView.bottom == view.bottom
        }
    }
    
    fileprivate func scheduleSearch() {
        let searchSelector = #selector(TextSearchViewController.search)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: searchSelector, object: .none)
        self.perform(searchSelector, with: .none, afterDelay: 0.3)
    }
    
    @objc fileprivate func search() {
        let searchSelector = #selector(TextSearchViewController.search)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: searchSelector, object: .none)
        textSearchQuery?.cancel()
        textSearchQuery = nil

        guard let query = self.searchQuery, !query.isEmpty else {
            self.results = []
            return
        }

        textSearchQuery = TextSearchQuery(conversation: conversation, query: query, delegate: self)
        textSearchQuery?.execute()
        self.showLoadingView = true
    }

}

extension TextSearchViewController: TextSearchQueryDelegate {

    func textSearchQueryDidReceive(result: TextQueryResult) {
        guard result.query == textSearchQuery else { return }
        if result.matches.count > 0 || !result.hasMore {
            showLoadingView = false
            results = result.matches
            tableView.reloadData()
        }
    }

}

extension TextSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.scheduleSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.search()
    }
}

extension TextSearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TextSearchResultCell.reuseIdentifier) as! TextSearchResultCell
        cell.query = self.searchQuery
        cell.message = self.results[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.wants(toPerform: .showInConversation, for: self.results[indexPath.row])
    }
}