//
//  GroupsViewController.swift
//  Connectly
//
//  Created by SPSOFT on 19/11/25.

import UIKit
import MBProgressHUD
import SDWebImage

class GroupsViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var groupsTableView: UITableView!
    @IBOutlet weak var userStatus: UIImageView!
    @IBOutlet weak var selectedGroupLabel: UILabel!
    
    // MARK: - Variables
    var isCreator: Bool?
    var groupID: Int?
    var groupName: String?
    var groupDescription: String?
    var groupIcon: String?
    
    var groups: [Datum] = []
    var filteredGroups: [Datum] = []
    
    
    // MARK: - Empty State Label
    private let emptyGroupsLabel: UILabel = {
        let label = UILabel()
        label.text = "No groups created yet.\nCreate one now!"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .gray
        label.isUserInteractionEnabled = true
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupEmptyLabelTap()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        
        loadProfileImageFromAppStorage()
        fetchCurrentStatus()
        groupsTableView.isPagingEnabled = false
        
    }
    
    
    // MARK: - UI Setup
    private func setupUI() {
        groupsTableView.delegate = self
        groupsTableView.dataSource = self
        groupsTableView.tableFooterView = UIView()
        
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.borderWidth = 0.3
    }
    
    private func setupEmptyLabelTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addButtonTappedFromEmptyState))
        emptyGroupsLabel.addGestureRecognizer(tapGesture)
    }
    
    @objc private func addButtonTappedFromEmptyState() {
        addButton(self)
    }
    
    // MARK: - Load Profile Image
    private func loadProfileImageFromAppStorage() {
        guard let path = Appstorage.profileImage,
              !path.isEmpty,
              let url = fullImageURL(path) else {
            profileImageView.image = UIImage(named: "ProfileImageIcon")
            return
        }
        
        profileImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
        profileImageView.sd_setImage(with: url) { [weak self] image, error, _, _ in
            self?.profileImageView.image = error == nil ? image : UIImage(named: "ProfileImageIcon")
        }
    }
    
    private func fullImageURL(_ path: String) -> URL? {
        if path.hasPrefix("http") {
            return URL(string: path)
        }
        return URL(string: "http://192.168.5.39:8000" + path)
    }
    
    // MARK: - Internet Reachability
    private func hasInternetConnection() -> Bool {
        let reachability = Reachability()
        return reachability?.connection == .wifi || reachability?.connection == .cellular
    }
    
    // MARK: - Fetch Groups
    private func fetchGroups() {
        self.view.endEditing(true)
        guard hasInternetConnection() else {
            showAlert("No internet connection")
            return
        }
        
        MBProgressHUD.showAdded(to: view, animated: true)
        
        NetworkManager.shared.load(
            path: "groups",
            method: .get,
            params: [:]
        ) { [weak self] data, error, success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                
                guard success == true, let data = data else { return }
                
                do {
                    let response = try JSONDecoder().decode(GetlistGroupModel.self, from: data)
                    print(response)
                    
                    // Update data source
                    self.groups = response.data ?? []
                    self.filteredGroups = self.groups
                    
                    // Reload table after data update
                    self.groupsTableView.reloadData()
                    
                    // Update empty state
                    self.updateEmptyState()
                    
                    print("Groups fetched:", self.groups.count)
                } catch {
                    self.showAlert("Failed to load groups")
                }
            }
        }
    }
    
    private func updateEmptyState() {
        if filteredGroups.isEmpty {
            groupsTableView.backgroundView = emptyGroupsLabel
        } else {
            groupsTableView.backgroundView = nil
        }
    }
    
    // MARK: - Fetch Current User Status
    private func fetchCurrentStatus() {
        self.view.endEditing(true)
        guard hasInternetConnection() else {
            showAlert("No internet connection")
            return
        }
        MBProgressHUD.showAdded(to: view, animated: true)
        
        NetworkManager.shared.load(
            path: "user/status",
            method: .get,
            params: [:]
        ) { [weak self] data, error, success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                guard success == true, let data = data else { return }
                
                do {
                    let response = try JSONDecoder().decode(ChangeStatusModel.self, from: data)
                    let status = response.data?.status ?? ""
                    self.updateUserStatusIcon(status: status)
                    
                } catch {
                    print("Status decode error:", error.localizedDescription)
                }
                self.fetchGroups()
            }
        }
    }
    
    // MARK: - Update Status Icon
    private func updateUserStatusIcon(status: String) {
        userStatus.contentMode = .scaleAspectFit
        
        switch status.lowercased() {
        case "available":
            userStatus.image = UIImage(systemName: "circle.fill")
            userStatus.tintColor = .systemGreen
            
        case "busy":
            userStatus.image = UIImage(systemName: "circle.fill")
            userStatus.tintColor = .systemOrange
            
        case "do_not_disturb", "dnd":
            userStatus.image = UIImage(systemName: "circle.fill")
            userStatus.tintColor = .systemRed
            
        default:
            userStatus.image = nil
        }
    }
    
    // MARK: - Actions
    @IBAction func groupsTabButton(_ sender: Any) {}
    
    @IBAction func notificationTabButton(_ sender: Any) {
        let notificationViewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "NotificationsViewController") as? NotificationsViewController
        self.navigationController?.pushViewController(notificationViewController!, animated: false)
        
    }
    
    @IBAction func settingsTabButton(_ sender: Any) {
        let settingsViewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController
        self.navigationController?.pushViewController(settingsViewController!, animated: false)
        
    }
    
    @IBAction func addButton(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "CreateGroupsViewController") as! CreateGroupsViewController
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    // MARK: - Navigation
    private func navigateToGroupNames(group: Datum) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "GroupNamesViewController") as? GroupNamesViewController else { return }
        
        vc.groupID = group.id
        vc.groupName = group.name
        vc.groupDescription = group.description
        vc.groupIcon = group.groupIcon
        vc.isCreator = group.isCreator ?? false
        
        vc.exitDelegate = self
        navigationController?.pushViewController(vc, animated: false)
    }
    
    // MARK: - Alert
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: appTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView
extension GroupsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredGroups.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell", for: indexPath) as! GroupsTableViewCell
        let group = filteredGroups[indexPath.row]
        cell.configure(with: group)
        
        
        cell.onGroupsButtonTap = { [weak self] selectedGroup in
            self?.navigateToGroupNames(group: selectedGroup)
        }
        
        
        return cell
    }
}

// MARK: - Group Exit Delegate
extension GroupsViewController: GroupExitDelegate {
    func didExitGroup() {
        fetchGroups()    // refresh list after exit
    }
}
extension UINavigationController {
    func popToViewController<T: UIViewController>(_ type: T.Type, storyboardID: String, storyboard: UIStoryboard) {
        if let existingVC = viewControllers.first(where: { $0 is T }) {
            popToViewController(existingVC, animated: false)
        } else {
            let vc = storyboard.instantiateViewController(withIdentifier: storyboardID)
            pushViewController(vc, animated: false)
        }
    }
}

