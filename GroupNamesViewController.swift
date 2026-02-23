//////
//////  GroupNamesViewController.swift
//////  Connectly



import UIKit
import MBProgressHUD

// MARK: - Exit Delegate
protocol GroupExitDelegate: AnyObject {
    func didExitGroup()
}

class GroupNamesViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var selectedGroupLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var exitGroupButton: UIButton!
    
    // MARK: - Properties
    weak var exitDelegate: GroupExitDelegate?
    
    var groupID: Int?
    var groupName: String?
    var groupDescription: String?
    var groupIcon: String?
    
    
    var activeMembers: [Member] = []
    var pendingMembers: [PendingMember] = []
    
    var isCreator = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        hideAllButtons()
        applyPermissions()
        
        selectedGroupLabel.adjustsFontSizeToFitWidth = true
        selectedGroupLabel.minimumScaleFactor = 0.7
        selectedGroupLabel.numberOfLines = 2
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        fetchGroupMembers()
    }
    
    // MARK: - Setup
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
    
    private func hideAllButtons() {
        addButton.isHidden = true
        inviteButton.isHidden = true
        editButton.isHidden = true
        deleteButton.isHidden = true
        exitGroupButton.isHidden = true
    }
    
    private func applyPermissions() {
        if isCreator {
            addButton.isHidden = false
            inviteButton.isHidden = false
            editButton.isHidden = false
            deleteButton.isHidden = false
            exitGroupButton.isHidden = true
        } else {
            exitGroupButton.isHidden = false
        }
    }
    // MARK: - API
    private func fetchGroupMembers() {
        self.view.endEditing(true)
        guard let groupID else { return }
        
        MBProgressHUD.showAdded(to: view, animated: true)
        
        NetworkManager.shared.load(
            path: "groups/\(groupID)",
            method: .get,
            params: [:]
        ) { [weak self] data, _, success in
            guard let self else { return }
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                guard success == true, let data else { return }
                
                do {
                    let response = try JSONDecoder().decode(GroupNamesModel.self, from: data)
                    guard let group = response.data else { return }
                    
                    self.selectedGroupLabel.text = group.groupName
                    self.groupName = group.groupName
                    self.groupDescription = group.groupDescription
                    self.groupIcon = group.groupIcon
                    
                    self.activeMembers = group.members ?? []
                    self.pendingMembers = group.pendingMembers ?? []
                    let myId = UserDefaults.standard.integer(forKey: "user_id")
                    
                    if let me = self.activeMembers.first(where: { $0.userID == myId }) {
                        self.isCreator = me.isCreator ?? false
                    }
                    self.applyPermissions()
                    self.tableView.reloadData()
                    
                } catch {
                    print("❌ Decode error:", error)
                }
            }
        }
    }
    func currentUserID() -> Int? {
        if let id = UserDefaults.standard.value(forKey: "user_id") as? Int {
            return id
        }
        if let str = UserDefaults.standard.value(forKey: "user_id") as? String {
            return Int(str)
        }
        return nil
    }
    
    
    
    // MARK: - Nickname Update
    private func updateNickname(userID: Int, nickname: String) {
        self.view.endEditing(true)
        MBProgressHUD.showAdded(to: view, animated: true)
        
        NetworkManager.shared.load(
            path: "users/nickname",
            method: .post,
            params: [
                "target_user_id": userID,
                "nickname": nickname
            ]
        ) { [weak self] _, _, success in
            guard let self, success == true else { return }
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                
                if let index = self.activeMembers.firstIndex(where: { $0.userID == userID }) {
                    self.activeMembers[index].nickname = nickname
                    self.tableView.reloadRows(
                        at: [IndexPath(row: index, section: 0)],
                        with: .none
                        
                    )
                }
            }
        }
    }
    
    // MARK: - Button Actions
    @IBAction func addButtonTapped(_ sender: UIButton) {
        guard isCreator, let groupID else { return }
        
        let vc = storyboard?.instantiateViewController(
            withIdentifier: "AddMembersViewController"
        ) as! AddMembersViewController
        
        vc.groupID = groupID
        vc.ProfileImage = groupIcon
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func inviteButtonTapped(_ sender: UIButton) {
        guard isCreator, let groupID else { return }
        
        let vc = storyboard?.instantiateViewController(
            withIdentifier: "InviteMembersViewController"
        ) as! InviteMembersViewController
        
        vc.groupID = groupID
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        guard isCreator, let groupID else { return }
        
        let vc = storyboard?.instantiateViewController(
            withIdentifier: "EditGroupViewController"
        ) as! EditGroupViewController
        
        vc.groupID = groupID
        vc.groupName = groupName ?? ""
        vc.groupDescription = groupDescription ?? ""
        vc.groupIcon = groupIcon
        
        vc.members = activeMembers.map {
            EditMember(
                userID: $0.userID,
                displayName: $0.displayName,
                email: $0.email,
                profileImage: $0.profileImage,
                isCreator: $0.isCreator
            )
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        guard isCreator, let groupID else { return }
        
        let alert = UIAlertController(
            title: "Delete Group",
            message: "Are you sure you want to delete this group?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteGroup(groupID: groupID)
        })
        
        present(alert, animated: true)
    }
    
    @IBAction func exitGroupButtonTapped(_ sender: UIButton) {
        
        
        let alert = UIAlertController(
            title: "Exit Group",
            message: "Are you sure you want to exit this group?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { _ in
            guard let groupID = self.groupID else { return }
            self.exitGroup(groupID: groupID)
        })
        
        present(alert, animated: true)
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: false)
        
    }
    
    // MARK: - Group Actions
    private func deleteGroup(groupID: Int) {
        self.view.endEditing(true)
        //        guard let groupID else { return }
        
        MBProgressHUD.showAdded(to: view, animated: true)
        
        NetworkManager.shared.load(
            path: "groups/\(groupID)",
            method: .delete,
            params: [:]
        ) { [weak self] _, _, success in
            guard let self else { return }
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                if success == true {
                    self.exitDelegate?.didExitGroup()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    private func exitGroup(groupID: Int) {
        self.view.endEditing(true)
        MBProgressHUD.showAdded(to: view, animated: true)
        
        NetworkManager.shared.load(
            path: "groups/exit",
            method: .post,
            params: ["group_id": groupID]
        ) { [weak self] _, _, success in
            guard let self else { return }
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                if success == true {
                    self.exitDelegate?.didExitGroup()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}
// MARK: - TableView
extension GroupNamesViewController: UITableViewDataSource, UITableViewDelegate, GroupMemberNicknameDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        pendingMembers.isEmpty ? 1 : 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? activeMembers.count : pendingMembers.count
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .white // or any background you want
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 16) // your font
        label.text = section == 0 ? "Active Members" : "Pending Members"
        
        // Set color with alpha
        label.textColor = UIColor.label.withAlphaComponent(0.8) // 1.0 = full, 0.5 = semi-transparent
        
        headerView.addSubview(label)
        
        // Constraints to pin label to left + center vertically
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
            
        ])
        
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30 // or whatever height you want
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "GroupNamesCell",
            for: indexPath
        ) as! GroupNamesTableViewCell
        
        cell.delegate = self
        
        
        if indexPath.section == 0 {
            cell.configureActiveMember(
                activeMembers[indexPath.row],
                indexPath: indexPath,
                isCurrentUserCreator: isCreator,
                currentUserID: currentUserID()
            )
            
        } else {
            cell.configurePendingMember(pendingMembers[indexPath.row])
        }
        
        return cell
    }
    
    func didTapEditNickname(member: Member, indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Nickname",
            message: "Visible only to you",
            preferredStyle: .alert
        )
        
        alert.addTextField {
            $0.text = member.nickname ?? member.displayName
            $0.placeholder = "Enter name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self,
                  let nickname = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !nickname.isEmpty,
                  let userID = member.userID else { return }
            
            self.updateNickname(userID: userID, nickname: nickname)
        })
        
        present(alert, animated: true)
    }
}
