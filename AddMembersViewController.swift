//
//  AddMembersViewController.swift
//  Connectly
//
//  Created by SPSOFT on 09/12/25.

import UIKit
import MBProgressHUD
import SDWebImage

// MARK: - Delegate
protocol AddMembersDelegate: AnyObject {
    func didAddMembers()
}

class AddMembersViewController: UIViewController, UITextFieldDelegate {
    
    
    
    // MARK: - IBOutlets
    @IBOutlet weak var addMembersLabel: UILabel!
    @IBOutlet weak var searchWithEmailTextField: UITextField! {
        didSet {
            searchWithEmailTextField.setLeftView()
            searchWithEmailTextField.delegate = self
            searchWithEmailTextField.keyboardType = .emailAddress
            searchWithEmailTextField.autocapitalizationType = .none
            searchWithEmailTextField.autocorrectionType = .no
            searchWithEmailTextField.textContentType = .username
            searchWithEmailTextField.smartInsertDeleteType = .no
            searchWithEmailTextField.alpha = 0.7
            searchWithEmailTextField.attributedPlaceholder = NSAttributedString(
                string: "Search With Email",
                attributes: [.foregroundColor: UIColor.black]
            )
        }
    }
    
    @IBOutlet weak var membersTableView: UITableView!
    @IBOutlet weak var selectedContainerView: UIView!
    @IBOutlet weak var selectedScrollView: UIScrollView!
    @IBOutlet weak var selectedStackView: UIStackView!
    
    // MARK: - Variables
    var groupID: Int!
    var ProfileImage: String!
    
    private var members: [Results] = []
    private var filteredMembers: [Results] = []
    private var selectedMemberIDs = Set<Int>()
    private var existingMemberIDs = Set<Int>()
    private var pendingMemberIDs = Set<Int>()
    private var selectedMembers: [Results] = []
    
    var maxSelectionLimit: Int? = nil
    
    // MARK: - Empty State
    private let noDataLabel: UILabel = {
        let label = UILabel()
        label.text = "No user found yet."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .gray
        return label
    }()
    private let emptySelectedLabel: UILabel = {
        let label = UILabel()
        label.text = "         No member selected. Please select a member!"
        label.textAlignment = .center
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Important: give fixed width for horizontal stack
        label.widthAnchor.constraint(equalToConstant: 390).isActive = true
        
        return label
    }()


    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupScrollViewLayout()
        fetchMembers()
//        selectedContainerView.isHidden = true
        updateSelectedScrollView()

    }
    
    // MARK: - Setup UI
    private func setupUI() {
        membersTableView.delegate = self
        membersTableView.dataSource = self
        
        searchWithEmailTextField.addTarget(
            self,
            action: #selector(searchTextChanged),
            for: .editingChanged
        )
    }
    
    // MARK: - Proper Scroll Layout
    private func setupScrollViewLayout() {

        selectedScrollView.showsHorizontalScrollIndicator = true
        selectedScrollView.alwaysBounceHorizontal = true

        selectedStackView.axis = .horizontal
        selectedStackView.alignment = .center
        selectedStackView.distribution = .fill
        selectedStackView.spacing = 12

        selectedStackView.translatesAutoresizingMaskIntoConstraints = false

        selectedStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        selectedStackView.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            selectedStackView.leadingAnchor.constraint(equalTo: selectedScrollView.contentLayoutGuide.leadingAnchor, constant: 8),
            selectedStackView.trailingAnchor.constraint(equalTo: selectedScrollView.contentLayoutGuide.trailingAnchor, constant: 8),
            selectedStackView.topAnchor.constraint(equalTo: selectedScrollView.contentLayoutGuide.topAnchor),
            selectedStackView.bottomAnchor.constraint(equalTo: selectedScrollView.contentLayoutGuide.bottomAnchor),
            selectedStackView.heightAnchor.constraint(equalTo: selectedScrollView.frameLayoutGuide.heightAnchor)
        ])
    }



    // MARK: - Empty State
    private func updateEmptyState() {
        membersTableView.backgroundView = filteredMembers.isEmpty ? noDataLabel : nil
    }
    
    // MARK: - Search
    @objc private func searchTextChanged() {
        let query = searchWithEmailTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if query.isEmpty {
            filteredMembers = members
            membersTableView.reloadData()
            updateEmptyState()
        } else {
            fetchMembersWithQuery(query)
        }
    }
    
    @IBAction func searchButtonTapped(_ sender: Any) {
        searchTextChanged()
    }
    
    // MARK: - API Search
    private func fetchMembersWithQuery(_ query: String) {
        guard let groupID else { return }
        
        MBProgressHUD.showAdded(to: view, animated: true)
        
        NetworkManager.shared.load(
            path: "groups/\(groupID)/search-members",
            method: .get,
            params: ["q": query]
        ) { [weak self] data, _, success in
            
            guard let self else { return }
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                
                guard success == true, let data else { return }
                
                do {
                    let response = try JSONDecoder()
                        .decode(FetchMemberModel.self, from: data)
                    
                    self.filteredMembers = response.data?.results ?? []
                    self.membersTableView.reloadData()
                    self.updateEmptyState()
                    
                } catch {
                    print("Decode error:", error)
                }
            }
        }
    }
    
    // MARK: - Fetch Members
    private func fetchMembers() {
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
                    let response = try JSONDecoder()
                        .decode(GroupNamesModel.self, from: data)
                    
                    let apiMembers = response.data?.members ?? []
                    let apiPendingMembers = response.data?.pendingMembers ?? []
                    
                    self.existingMemberIDs = Set(apiMembers.compactMap { $0.userID })
                    self.pendingMemberIDs = Set(apiPendingMembers.compactMap { $0.userID })
                    
                    self.members = apiMembers.map {
                        Results(
                            userID: $0.userID,
                            name: $0.displayName,
                            email: $0.email,
                            profileImage: $0.profileImage
                        )
                    }
                    
                    self.filteredMembers = self.members
                    self.membersTableView.reloadData()
                    self.updateEmptyState()
                    
                } catch {
                    print("Decode error:", error)
                }
            }
        }
    }
    
    // MARK: - Submit
    @IBAction func submitButtonTapped(_ sender: Any) {
        
        if filteredMembers.isEmpty {
            showAlert("No user found.")
            return
        }
        
        if selectedMemberIDs.isEmpty {
            showAlert("Please select at least one member.")
            return
        }
        
        addMemberService()
    }
    
    private func addMemberService() {
        guard let groupID else { return }
        
        MBProgressHUD.showAdded(to: view, animated: true)
        
        let params: [String: Any] = [
            "group_id": groupID,
            "user_ids": Array(selectedMemberIDs)
        ]
        
        NetworkManager.shared.load(
            path: "groups/add-members",
            method: .post,
            params: params
        ) { [weak self] _, _, success in
            
            guard let self else { return }
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                
                if success == true {
                    self.showAlertAndPop("Invitation notification sent successfully.")
                } else {
                    self.showAlert("Failed to add members.")
                }
            }
        }
    }
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Update Scroll
    private func updateSelectedScrollView() {

        // Remove everything
        selectedStackView.arrangedSubviews.forEach {
            selectedStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        // Always horizontal layout
        selectedStackView.axis = .horizontal
        selectedStackView.alignment = .center
        selectedStackView.distribution = .fill
        selectedStackView.spacing = 6

        if selectedMembers.isEmpty {
            
            // Show message only
            selectedStackView.addArrangedSubview(emptySelectedLabel)
            
        } else {
            
            // Hide message automatically (by not adding it)
            for member in selectedMembers {
                selectedStackView.addArrangedSubview(createMemberView(member))
            }
        }

        DispatchQueue.main.async {
            self.selectedScrollView.setContentOffset(.zero, animated: false)
        }
    }

    
    private func fullImageURL(_ path: String) -> URL? {
        if path.hasPrefix("http") {
            return URL(string: path)
        }
        return URL(string: "http://192.168.5.39:8000" + path)
    }
    
    private func createMemberView(_ member: Results) -> UIView {

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalToConstant: 90).isActive = true
        container.setContentCompressionResistancePriority(.required, for: .horizontal)
        container.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // IMAGE
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.backgroundColor = .systemGray5

        if let path = member.profileImage,
           !path.isEmpty,
           let url = fullImageURL(path) {
            imageView.sd_setImage(with: url)
        } else {
            imageView.image = UIImage(named: "ProfileImageIcon")
        }

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 50),
            imageView.heightAnchor.constraint(equalToConstant: 50)
        ])

        // LABEL
        let nameLabel = UILabel()
        nameLabel.text = member.name
        nameLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail

        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(nameLabel)

        // REMOVE BUTTON
        let removeButton = UIButton(type: .custom)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.setTitle("✕", for: .normal)
        removeButton.setTitleColor(.white, for: .normal)
        removeButton.backgroundColor = .systemRed
        removeButton.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        removeButton.layer.cornerRadius = 10
        removeButton.tag = member.userID ?? 0

        removeButton.addTarget(self,
                               action: #selector(removeSelectedMember(_:)),
                               for: .touchUpInside)

        container.addSubview(removeButton)

        NSLayoutConstraint.activate([
            removeButton.widthAnchor.constraint(equalToConstant: 20),
            removeButton.heightAnchor.constraint(equalToConstant: 20),
            removeButton.topAnchor.constraint(equalTo: imageView.topAnchor, constant: -5),
            removeButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 5)
        ])

        return container
    }

    
    @objc private func removeSelectedMember(_ sender: UIButton) {
        
        let id = sender.tag
        
        let alert = UIAlertController(
            title: "Remove Member",
            message: "Are you sure you want to remove this member?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { _ in
            
            self.selectedMemberIDs.remove(id)
            self.selectedMembers.removeAll { $0.userID == id }
            
            self.membersTableView.reloadData()
            self.updateSelectedScrollView()
        })
        
        present(alert, animated: true)
    }
    
    
    // MARK: - Alerts
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showAlertAndPop(_ message: String) {
        let alert = UIAlertController(title: "Message", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
// MARK: - TableView
extension AddMembersViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return filteredMembers.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "AddMemberCell",
            for: indexPath
        ) as! AddMemberaTableViewCell
        
        let member = filteredMembers[indexPath.row]
        let userID = member.userID ?? -1
        
        let isSelected = selectedMemberIDs.contains(userID)
        let isExisting = existingMemberIDs.contains(userID)
        let isPending = pendingMemberIDs.contains(userID)
        
        cell.configure(
            with: member,
            isSelected: isSelected,
            isExistingMember: isExisting,
            isPendingMember: isPending
        )
        
        cell.onCheckmarkTap = { [weak self] in
            guard let self, let id = member.userID else { return }
            
            if self.existingMemberIDs.contains(id) {
                self.showAlert("User already a group member.")
                return
            }
            
            if self.pendingMemberIDs.contains(id) {
                self.showAlert("User already invited.")
                return
            }
            if self.selectedMemberIDs.contains(id) {
                self.selectedMemberIDs.remove(id)
                self.selectedMembers.removeAll { $0.userID == id }
            } else {
                self.selectedMemberIDs.insert(id)
                self.selectedMembers.append(member)
            
            }
            
            self.updateSelectedScrollView()
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        
        return cell
        
}}
