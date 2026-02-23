
//  EditGroupViewController.swift
//  Connectly

//  Created by SPSOFT on 09/12/25.

import UIKit
import MBProgressHUD

// ✅ UPDATED: Delegate to refresh previous screen
protocol EditGroupDelegate: AnyObject {
    func didUpdateGroup()
}

class EditGroupViewController: UIViewController,
                               UITableViewDelegate,
                               UITableViewDataSource,
                               ImagePickerDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var editGroupLabel: UILabel!
    @IBOutlet weak var profile: UIImageView!
    @IBOutlet weak var groupNameTextField: UITextField!{
        didSet {
            groupNameTextField.setLeftView()
            groupNameTextField.delegate = self
            groupNameTextField.keyboardType = .emailAddress
            groupNameTextField.autocapitalizationType = .none
            groupNameTextField.autocorrectionType = .no
            groupNameTextField.textContentType = .username
            groupNameTextField.smartInsertDeleteType = .no
        }
    }
    
    @IBOutlet weak var groupDescriptionTextView: UITextView!{
        didSet {
            groupDescriptionTextView.delegate = self
            groupDescriptionTextView.keyboardType = .default
            groupDescriptionTextView.autocapitalizationType = .sentences
            groupDescriptionTextView.autocorrectionType = .yes
            groupDescriptionTextView.textContentType = .none
            groupDescriptionTextView.smartInsertDeleteType = .no
        }
    }
    
    @IBOutlet weak var editGroupTableView: UITableView!
    
    // MARK: - Variables
    var groupID: Int = 0
    var groupName: String = ""
    var groupDescription: String = ""
    var groupIcon: String?
    
    var members: [EditMember] = []
    var selectedMembers = Set<Int>()
    
    var imagePicker: ImagePicker!
    var profileImageBase64: String?
    
    private let loggedInUserID = UserDefaults.standard.integer(forKey: "user_id")
    
    // ✅ UPDATED
    weak var delegate: EditGroupDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
        setupInitialData()
    }
    
    // MARK: - Initial Setup
    private func setupInitialData() {
        
        groupNameTextField.text = groupName
        groupDescriptionTextView.text = groupDescription
        groupDescriptionTextView.layer.borderWidth = 1
        groupDescriptionTextView.layer.borderColor = UIColor.black.cgColor
        
        // ✅ All members checked initially
        selectedMembers = Set(members.compactMap { $0.userID })
        
        loadGroupIcon()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        setupProfileImage()
    }
    
    private func setupTableView() {
        editGroupTableView.delegate = self
        editGroupTableView.dataSource = self
        editGroupTableView.tableFooterView = UIView()
        editGroupTableView.layer.borderColor = UIColor.black.cgColor
        editGroupTableView.layer.borderWidth = 0.5
    }
    
    private func setupProfileImage() {
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(selectProfileImage)
        )
        profile.isUserInteractionEnabled = true
        profile.addGestureRecognizer(tapGesture)
        profile.layer.cornerRadius = profile.frame.height / 2
        profile.clipsToBounds = true
        profile.layer.borderWidth = 1
        profile.layer.borderColor = UIColor.black.cgColor
    }
    
    // MARK: - Load Group Icon
    private func loadGroupIcon() {
        guard let iconPath = groupIcon, !iconPath.isEmpty else { return }
        
        let fullURL = "http://192.168.5.39:8000" + iconPath
        guard let encoded = fullURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self,
                  let data,
                  let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self.profile.image = image
            }
        }.resume()
    }
    
    // MARK: - Image Picker
    @objc func selectProfileImage() {
        imagePicker = ImagePicker(
            presentationController: self,
            delegate: self
        )
        imagePicker.present(from: profile)
    }
    
    func didSelect(image: UIImage?) {
        guard let img = image else { return }
        profile.image = img
        
        if let data = img.jpegData(compressionQuality: 0.5) {
            profileImageBase64 = data.base64EncodedString()
        }
    }
    
    // MARK: - Actions
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // ✅ UPDATED: Confirmation alert added
    @IBAction func editGroupButton(_ sender: Any) {
        
        guard let name = groupNameTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            noActionAlertView(
                title: appTitle,
                message: "Please enter group name"
            )
            return
        }
        
        let alert = UIAlertController(
            title: "Update Group",
            message: "Are you sure you want to update the changes?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self else { return }
            
            let reachability = Reachability()
            guard reachability?.connection == .wifi ||
                    reachability?.connection == .cellular else {
                self.noActionAlertView(
                    title: appTitle,
                    message: noInternetMessage
                )
                return
            }
            
            self.serviceForEditGroup(
                groupID: self.groupID,
                groupName: name,
                groupDescription: self.groupDescriptionTextView.text ?? "",
                groupIconBase64: self.profileImageBase64
            )
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Build Members Payload
    private func buildMembersPayload() -> [[String: Any]] {
        
        members.compactMap { member in
            guard let userID = member.userID else { return nil }
            
            // ❌ Cannot remove creator or self
            if member.isCreator == true || userID == loggedInUserID {
                return nil
            }
            
            if !selectedMembers.contains(userID) {
                return [
                    "user_id": userID,
                    "remove": true
                ]
            }
            return nil
        }
    }
    
    // MARK: - Edit Group API
    private func serviceForEditGroup(
        groupID: Int,
        groupName: String,
        groupDescription: String,
        groupIconBase64: String?
    ) {
        self.view.endEditing(true)
        
        startProgressHUD()
        
        var params: [String: Any] = [
            "group_id": groupID,
            "group_name": groupName,
            "group_description": groupDescription
        ]
        
        if let icon = groupIconBase64 {
            params["group_icon_base64"] = icon
        }
        
        let membersPayload = buildMembersPayload()
        if !membersPayload.isEmpty {
            params["members"] = membersPayload
        }
        
        NetworkManager.shared.load(
            path: "groups/edit",
            method: .put,
            params: params
        ) { [weak self] data, error, success in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.stopProgressHUD()
            }
            
            guard success == true, let data else {
                DispatchQueue.main.async {
                    self.noActionAlertView(
                        title: appTitle,
                        message: error?.localizedDescription ?? "Server error"
                    )
                }
                return
            }
            
            do {
                let response = try JSONDecoder()
                    .decode(EditGroupData.self, from: data)
                
                DispatchQueue.main.async {
                    self.singleActionAlertView(
                        title: appTitle,
                        message: response.message ?? "Group updated successfully."
                    ) { _ in
                        // ✅ UPDATED
                        self.delegate?.didUpdateGroup()
                        self.navigationController?.popViewController(animated: true)
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.noActionAlertView(
                        title: appTitle,
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        members.count
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "EditMemberCell",
            for: indexPath
        ) as! EditMemberTableViewCell
        
        let member = members[indexPath.row]
        guard let userID = member.userID else { return cell }
        
        let isSelected = selectedMembers.contains(userID)
        let isAdmin = member.isCreator ?? false
        
        cell.configure(
            with: member,
            isSelected: isSelected,
            isMember: true,
            isAdmin: isAdmin
        )
        
        cell.onCheckmarkTap = { [weak self] in
            guard let self else { return }
            
            // ❌ Creator / Self cannot be removed
            if member.isCreator == true || userID == self.loggedInUserID {
                return
            }
            
            if self.selectedMembers.contains(userID) {
                self.selectedMembers.remove(userID)
            } else {
                self.selectedMembers.insert(userID)
            }
            
            cell.updateCheckmarkState(
                isSelected: self.selectedMembers.contains(userID)
            )
        }
        
        return cell
    }
}
