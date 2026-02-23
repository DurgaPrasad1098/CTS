//  InviteMembersViewController.swift
//  Connectly
//
//  Created by SPSOFT on 19/11/25.
//

import UIKit
import MBProgressHUD

class InviteMembersViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var emailTextField: UITextField!{
        didSet {
            emailTextField.setLeftView()
            emailTextField.delegate = self
            emailTextField.keyboardType = .emailAddress
            emailTextField.autocapitalizationType = .none
            emailTextField.autocorrectionType = .no
            emailTextField.textContentType = .username
            emailTextField.smartInsertDeleteType = .no
            emailTextField.alpha = 1
            emailTextField.attributedPlaceholder = NSAttributedString(
                string: "Search With Email",
                attributes: [
                    .foregroundColor: UIColor.black
                ])
        }
    }
    
    @IBOutlet weak var inviteTableView: UITableView!
    
    // MARK: - Variables
    var groupID: Int?
    private var invitedMembers: [IniviteDatum] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        
        guard groupID != nil else {
            noActionAlertView(title: appTitle,
                              message: "Group ID not set. Cannot fetch invites.")
            return
        }
        
        fetchPendingInvites()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
    }
    
    private func setupTableView() {
        inviteTableView.delegate = self
        inviteTableView.dataSource = self
        inviteTableView.tableFooterView = UIView()
        inviteTableView.layer.borderColor = UIColor.black.cgColor
        inviteTableView.layer.borderWidth = 0.5
        inviteTableView.clipsToBounds = true
    }
    
    // MARK: - Actions
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func inviteMembersButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            noActionAlertView(title: appTitle, message: "Please enter email.")
            return
        }
        
        guard email.isValidEmail else {
            noActionAlertView(title: appTitle, message: "Please enter a valid email address.")
            return
        }
        
        // ✅ Network Reachability Check
        let reachability = Reachability()
        if reachability?.connection == .wifi || reachability?.connection == .cellular {
            // Only call the invite API if internet is available
            serviceForInviteMember(email: email)
        } else {
            noActionAlertView(title: appTitle, message: "No internet connection")
        }
    }
    
    // MARK: - Invite Member API
    private func serviceForInviteMember(email: String) {
        self.view.endEditing(true)
        guard let groupID = groupID else {
            noActionAlertView(title: appTitle,
                              message: "Group ID missing.")
            return
        }
        
        view.endEditing(true)
        startProgressHUD()
        
        let params: [String: Any] = [ "group_id": groupID,
                                      "email": email]
        
        NetworkManager.shared.load(
            path: "groups/invite-member",
            method: .post,
            params: params
        ) { [weak self] data, error, success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.stopProgressHUD()
                
                if let error = error {
                    self.noActionAlertView(title: appTitle,
                                           message: error.localizedDescription)
                    return
                }
                
                guard success == true, let data else {
                    self.noActionAlertView(title: appTitle,
                                           message: "Something went wrong.")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(InviteModel.self, from: data)
                    //let response = try JSONSerialization.jsonObject(with: responseData, options: .mutableContainers)
                    print(response)
                    
                    if response.success == true {
                        self.noActionAlertView(title: appTitle,
                                               message: response.message ?? "Invitation sent successfully.")
                        let vc = UIStoryboard(name: "Main", bundle: nil)
                            .instantiateViewController(withIdentifier: "GroupsViewController") as! GroupsViewController
                        self.navigationController?.pushViewController(vc, animated: true)
                        
                        self.emailTextField.text = ""
                        self.fetchPendingInvites()
                    } else {
                        self.noActionAlertView(title: appTitle,
                                               message: response.message ?? "Failed to invite member.")
                    }
                } catch {
                    self.noActionAlertView(title: appTitle,
                                           message: "Invalid server response.")
                }
            }
        }
    }
    
    // MARK: - Fetch Pending Invites
    private func fetchPendingInvites() {
        self.view.endEditing(true)
        guard let groupID = groupID else { return }
        
        startProgressHUD()
        
        NetworkManager.shared.load(
            path: "groups/\(groupID)/pending-invites",
            method: .get,
            params: [:]
        ) { [weak self] data, error, success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.stopProgressHUD()
                
                if let error = error {
                    self.noActionAlertView(title: appTitle,
                                           message: error.localizedDescription)
                    return
                }
                
                guard success == true, let data = data else {
                    self.noActionAlertView(title: appTitle,
                                           message: "Failed to fetch invites.")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(PendingInviteModel.self, from: data)
                    self.invitedMembers = response.data ?? []
                    self.inviteTableView.reloadData()
                } catch {
                    self.noActionAlertView(title: appTitle,
                                           message: "Unable to load invites.")
                }
            }
        }
    }
    
    // MARK: - Re-Invite Member
    private func serviceForReinviteMember(inviteID: Int) {
        guard let groupID = groupID else { return }
        
        startProgressHUD()
        
        let params: [String: Any] = ["group_id": groupID,
                                     "invite_id": inviteID]
        NetworkManager.shared.load(
            path: "groups/reinvite",
            method: .post,
            params: params
        ) { [weak self] data, error, success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.stopProgressHUD()
                
                if let error = error {
                    self.noActionAlertView(title: appTitle,
                                           message: error.localizedDescription)
                    return
                }
                
                guard success == true, let data = data else {
                    self.noActionAlertView(title: appTitle,
                                           message: "Something went wrong.")
                    return
                }
                
                let response = try? JSONDecoder().decode(ReInviteModel.self, from: data)
                self.noActionAlertView(title: appTitle,
                                       message: response?.message ?? "Invitation resent successfully.")
            }
        }
    }
}

// MARK: - TableView
extension InviteMembersViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        invitedMembers.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "InviteCell",
            for: indexPath
        ) as! InviteMembersTableViewCell
        
        let member = invitedMembers[indexPath.row]
        
        cell.configure(
            email: member.email ?? "",
            status: "Pending"
        )
        
        cell.onResendTap = { [weak self] in
            guard let inviteID = member.inviteID else { return }
            self?.serviceForReinviteMember(inviteID: inviteID)
        }
        
        return cell
    }
}
