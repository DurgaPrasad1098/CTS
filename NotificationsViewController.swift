//
//  NotificationsViewController.swift
//  Connectly
//



import UIKit
import MBProgressHUD
import SDWebImage

class NotificationsViewController: UIViewController,
                                   UITableViewDelegate,
                                   UITableViewDataSource {
    
    // MARK: - Outlets
    @IBOutlet weak var profile: UIImageView!
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var notificationsTableView: UITableView!
    @IBOutlet weak var userStatus: UIImageView!
    
    // MARK: - Properties
    private var notifications: [NotificationDatum] = []
    
    // MARK: - Empty State Label
    private let emptyNotificationsLabel: UILabel = {
        let label = UILabel()
        label.text = "No notifications yet.\nCheck back later!"
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
        loadProfileImageFromAppStorage()
        DispatchQueue.main.async { [weak self] in
            self?.fetchCurrentStatus()
            self?.fetchNotifications()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profile.layer.cornerRadius = profile.frame.width / 2
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        profile.layer.cornerRadius = profile.frame.width / 2
        profile.clipsToBounds = true
        profile.contentMode = .scaleAspectFill
        profile.isUserInteractionEnabled = true
        profile.layer.borderWidth = 0.3
        
        notificationsTableView.delegate = self
        notificationsTableView.dataSource = self
        notificationsTableView.tableFooterView = UIView()
    }
    
    private func setupEmptyLabelTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(emptyNotificationsTapped))
        emptyNotificationsLabel.addGestureRecognizer(tapGesture)
    }
    
    @objc private func emptyNotificationsTapped() {
        // Navigate to Groups when empty message is tapped
        if let vc = storyboard?.instantiateViewController(withIdentifier: "GroupsViewController") as? GroupsViewController {
            navigationController?.pushViewController(vc, animated: true)
            
        }
    }
    
    // MARK: - Load Profile Image
    private func loadProfileImageFromAppStorage() {
        guard let path = Appstorage.profileImage, !path.isEmpty else {
            profile.image = UIImage(named: "ProfileImageIcon")
            return
        }
        
        var urlString = path
        if !urlString.hasPrefix("http") {
            urlString = "http://192.168.5.39:8000" + urlString
        }
        
        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else {
            profile.image = UIImage(named: "ProfileImageIcon")
            return
        }
        
        profile.sd_imageIndicator = SDWebImageActivityIndicator.medium
        profile.sd_setImage(
            with: url,
            placeholderImage: UIImage(named: "ProfileImageIcon"),
            options: [.retryFailed, .continueInBackground]
        )
    }
    
    // MARK: - Internet Check
    private func hasInternetConnection() -> Bool {
        let reachability = Reachability()
        return reachability?.connection == .wifi || reachability?.connection == .cellular
    }
    
    // MARK: - Fetch Notifications
    private func fetchNotifications() {
        self.view.endEditing(true)
        guard hasInternetConnection() else {
            noActionAlertView(title: appTitle, message: "No internet connection")
            return
        }
        
        startProgressHUD()
        
        NetworkManager.shared.load(
            path: "notifications",
            method: .get,
            params: [:]
        ) { [weak self] data, error, success in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.stopProgressHUD()
                
                if let error {
                    self.noActionAlertView(title: appTitle, message: error.localizedDescription)
                    return
                }
                
                guard success == true, let data else {
                    self.noActionAlertView(title: appTitle, message: "Something went wrong.")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(NotificationModel.self, from: data)
                    self.notifications = response.data ?? []
                    
                    self.notificationsTableView.reloadData()
                    self.updateEmptyState()
                } catch {
                    self.noActionAlertView(title: appTitle, message: "Invalid server response.")
                }
            }
        }
    }
    
    private func updateEmptyState() {
        if notifications.isEmpty {
            notificationsTableView.backgroundView = emptyNotificationsLabel
        } else {
            notificationsTableView.backgroundView = nil
        }
    }
    
    // MARK: - Accept Notification
    private func acceptNotification(notificationID: Int, completion: @escaping (Bool, String) -> Void) {
        guard hasInternetConnection() else {
            completion(false, "No internet connection")
            return
        }
        self.view.endEditing(true)
        
        startProgressHUD()
        
        NetworkManager.shared.load(
            path: "notifications/accept",
            method: .post,
            params: ["invite_id": notificationID]
        ) { [weak self] data, error, success in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.stopProgressHUD()
                
                if let error {
                    completion(false, error.localizedDescription)
                    return
                }
                
                guard success == true, let data else {
                    completion(false, "Something went wrong")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(AcceptNotificationModel.self, from: data)
                    completion(response.success ?? false,
                               response.message ?? (response.success == true ? "Accepted successfully" : "Failed to accept"))
                } catch {
                    completion(false, "Invalid server response")
                }
            }
        }
    }
    
    // MARK: - Reject Notification
    private func rejectNotification(notificationID: Int, completion: @escaping (Bool, String) -> Void) {
        guard hasInternetConnection() else {
            completion(false, "No internet connection")
            return
        }
        self.view.endEditing(true)
        
        startProgressHUD()
        
        NetworkManager.shared.load(
            path: "notifications/reject",
            method: .post,
            params: ["invite_id": notificationID]
        ) { [weak self] data, error, success in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.stopProgressHUD()
                
                if let error {
                    completion(false, error.localizedDescription)
                    return
                }
                
                guard success == true, let data else {
                    completion(false, "Something went wrong")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(RejectNotificationModel.self, from: data)
                    completion(response.success ?? false,
                               response.message ?? (response.success == true ? "Rejected successfully" : "Failed to reject"))
                } catch {
                    completion(false, "Invalid server response")
                }
            }
        }
    }
    
    // MARK: - Fetch Current User Status
    private func fetchCurrentStatus() {
        self.view.endEditing(true)
        MBProgressHUD.showAdded(to: view, animated: true)
        
        NetworkManager.shared.load(
            path: "user/status",
            method: .get,
            params: [:]
        ) { [weak self] data, _, success in
            guard let self else { return }
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                guard success == true, let data else { return }
                
                do {
                    let response = try JSONDecoder().decode(ChangeStatusModel.self, from: data)
                    self.updateUserStatusIcon(status: response.data?.status ?? "")
                } catch {
                    print("Status decode error:", error.localizedDescription)
                }
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
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationsCell", for: indexPath) as! NotificationsTableViewCell
        let notification = notifications[indexPath.row]
        cell.configure(with: notification)
        
        // Accept button
        cell.onAcceptTap = { [weak self] in
            guard let self, let notificationID = notification.notificationID else { return }
            self.showAcceptRejectAlert(notificationID: notificationID, isAccept: true)
        }
        
        // Reject button
        cell.onRejectTap = { [weak self] in
            guard let self, let notificationID = notification.notificationID else { return }
            self.showAcceptRejectAlert(notificationID: notificationID, isAccept: false)
        }
        
        return cell
    }
    
    private func showAcceptRejectAlert(notificationID: Int, isAccept: Bool) {
        let title = "Confirm"
        let message = isAccept ? "Are you sure you want to accept? You will be added directly to the group."
        : "Are you sure you want to reject this invitation?"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        let actionTitle = isAccept ? "Accept" : "Reject"
        let style: UIAlertAction.Style = isAccept ? .default : .destructive
        
        alert.addAction(UIAlertAction(title: actionTitle, style: style) { [weak self] _ in
            guard let self else { return }
            let completion: (Bool, String) -> Void = { success, message in
                let popup = UIAlertController(title: success ? "Success" : "Error", message: message, preferredStyle: .alert)
                popup.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    if success {
                        if let index = self.notifications.firstIndex(where: { $0.notificationID == notificationID }) {
                            self.notifications.remove(at: index)
                            self.notificationsTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                            self.updateEmptyState()
                        }
                        if isAccept, let vc = self.storyboard?.instantiateViewController(withIdentifier: "GroupsViewController") as? GroupsViewController {
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                })
                self.present(popup, animated: false)
            }
            
            if isAccept {
                self.acceptNotification(notificationID: notificationID, completion: completion)
            } else {
                self.rejectNotification(notificationID: notificationID, completion: completion)
            }
        })
        
        self.present(alert, animated: false)
    }
    
    // MARK: - Tab Buttons
    @IBAction func groupsTabButton(_ sender: Any) {
        let groupsViewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "GroupsViewController") as? GroupsViewController
        self.navigationController?.pushViewController(groupsViewController!, animated: false)
    }
    
    
    @IBAction func notificationTabButton(_ sender: Any) {
        // Current tab, do nothing
    }
    
    @IBAction func settingsTabButton(_ sender: Any) {
        
        let settingsViewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController
        self.navigationController?.pushViewController(settingsViewController!, animated: false)
        
    }
}
