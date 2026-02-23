//
//  SettingsViewController.swift
//  Connectly
//
//  Created by SPSOFT on 09/12/25.
//

import UIKit
import MBProgressHUD
import SDWebImage

class SettingsViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var profile: UIImageView!
    @IBOutlet weak var settingsLabel: UILabel!
    @IBOutlet weak var userStatus: UIImageView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // ✅ Fetch notifications immediately
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProfileImageFromAppStorage()
        DispatchQueue.main.async { [weak self] in
            self?.fetchCurrentStatus()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        profile.layer.cornerRadius = profile.frame.width / 2
        profile.clipsToBounds = true
        profile.contentMode = .scaleAspectFill
        profile.isUserInteractionEnabled = true
        profile.layer.borderWidth = 0.3
    }
    
    // MARK: - Load Profile Image (SDWebImage)
    private func loadProfileImageFromAppStorage() {
        
        guard let path = Appstorage.profileImage, !path.isEmpty else {
            profile.image = UIImage(named: "ProfileImageIcon")
            return
        }
        
        var urlString = path
        if !urlString.hasPrefix("http") {
            urlString = "http://192.168.5.39:8000" + urlString
        }
        
        guard let encoded = urlString.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ),
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
    
    // MARK: - Fetch Current User Status
    private func fetchCurrentStatus() {
        // ✅ Network Reachability Check
        let reachability = Reachability()
        guard reachability?.connection == .wifi || reachability?.connection == .cellular else {
            showAlert("No internet connection")
            return
        }
        
        MBProgressHUD.showAdded(to: view, animated: true)
        
        NetworkManager.shared.load(
            path: "user/status",
            method: .get,
            params: [:]
        ) { [weak self] data, _, success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                guard success == true, let data = data else { return }
                
                do {
                    let response = try JSONDecoder().decode(ChangeStatusModel.self, from: data)
                    let status = response.data?.status ?? ""
                    self.updateUserStatusIcon(status: status)
                } catch {
                    print("❌ Status decode error:", error.localizedDescription)
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
    
    
    // MARK: - Emoji → UIImage
    private func emojiImage(_ emoji: String, size: CGFloat = 24) -> UIImage? {
        let label = UILabel()
        label.text = emoji
        label.font = UIFont.systemFont(ofSize: size)
        label.sizeToFit()
        
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    // MARK: - Logout Confirmation Alert
    private func showLogoutAlert() {
        
        let alert = UIAlertController(
            title: appTitle,
            message: "Are you sure you want to logout?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            if let sceneDelegate = UIApplication.shared.connectedScenes
                .first?.delegate as? SceneDelegate {
                sceneDelegate.logout()
            }
        })
        
        present(alert, animated: true)
    }
    
    
    // MARK: - Actions
    @IBAction func setyourAvailableTimingsButton(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "AvailableTimingsViewController")
        navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func changeStatusButton(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "ChangeStatusViewController")
        navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func updateProfileButton(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "UpdateProfileViewController")
        as! UpdateProfileViewController
        
        vc.userID = Appstorage.userID
        vc.name = Appstorage.name
        vc.email = Appstorage.emailId
        vc.profileImageURLString = Appstorage.profileImage
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func changePasswordButton(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "ChangePasswordViewController")
        navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func logoutButton(_ sender: UIButton) {
        showLogoutAlert()
    }
    
    
    // MARK: - Bottom Tab Navigation
    @IBAction func groupsTabButton(_ sender: Any) {
        let groupsViewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "GroupsViewController") as? GroupsViewController
        self.navigationController?.pushViewController(groupsViewController!, animated: false)
    }
    
    @IBAction func notificationTabButton(_ sender: Any) {
        let notificationViewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "NotificationsViewController") as? NotificationsViewController
        self.navigationController?.pushViewController(notificationViewController!, animated: false)
        
    }
    
    @IBAction func settingsTabButton(_ sender: Any) {
    }
    
    // MARK: - Alerts
    private func showAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Connectly",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
