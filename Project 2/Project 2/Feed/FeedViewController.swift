//
//  FeedViewController.swift
//  BeRealDupe
//
//  Created by Cristobal Elizarrarz on 2/25/25.
//

import UIKit
import ParseSwift

class FeedViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    private let refreshControl = UIRefreshControl()

    private var posts = [Post]() {
        didSet {
            tableView.reloadData()
        }
    }

    private var isLoadingMorePosts = false
    private var currentPage = 0
    private let postsPerPage = 10

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false

        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)

        queryPosts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        queryPosts()
    }

    private func queryPosts(isLoadingMore: Bool = false, completion: (() -> Void)? = nil) {
        guard !isLoadingMorePosts else { return }
        isLoadingMorePosts = true

        let yesterdayDate = Calendar.current.date(byAdding: .day, value: (-1), to: Date())!

        let query = Post.query()
            .include("user")
            .order([.descending("createdAt")])
            .where("createdAt" >= yesterdayDate)
            .limit(postsPerPage)
            .skip(currentPage * postsPerPage)

        query.find { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let newPosts):
                if isLoadingMore {
                    self.posts.append(contentsOf: newPosts)
                } else {
                    self.posts = newPosts // Reset posts when refreshing
                }
                self.currentPage = isLoadingMore ? self.currentPage + 1 : 1
            case .failure(let error):
                self.showAlert(description: error.localizedDescription)
            }

            self.isLoadingMorePosts = false
            completion?()
        }
    }

    @IBAction func onLogOutTapped(_ sender: Any) {
        showConfirmLogoutAlert()
    }

    @objc private func onPullToRefresh() {
        refreshControl.beginRefreshing()
        currentPage = 0
        isLoadingMorePosts = false
        queryPosts { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(
            title: "Log out of \(User.current?.username ?? "current account")?",
            message: nil,
            preferredStyle: .alert
        )
        let logOutAction = UIAlertAction(title: "Log out", style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
}

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        cell.configure(with: posts[indexPath.row])
        return cell
    }
}

extension FeedViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let tableViewHeight = scrollView.frame.size.height
        
        if offsetY > contentHeight - tableViewHeight * 1.5 {
            queryPosts(isLoadingMore: true)
        }
    }
}
