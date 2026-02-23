//
//  ChangeStatusViewController.swift
//  Connectly
//

//
import UIKit
import MBProgressHUD

class ChangeStatusViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var availableView: UIView!
    @IBOutlet weak var busyView: UIView!
    @IBOutlet weak var dndView: UIView!
    
    @IBOutlet weak var availableButton: UIButton!
    @IBOutlet weak var busyButton: UIButton!
    @IBOutlet weak var dndButton: UIButton!
    
    // MARK: - Status Enum
    enum UserStatus {
        case available
        case busy
        case doNotDisturb
        
        /// Value expected by BACKEND (PUT API)
        var apiValue: String {
            switch self {
            case .available:
                return "available"
            case .busy:
                return "busy"
            case .doNotDisturb:
                return "dnd"
            }
        }
        
        /// Display value for Alert
        var displayValue: String {
            switch self {
            case .available:
                return "Available"
            case .busy:
                return "Busy"
            case .doNotDisturb:
                return "Do Not Disturb"
            }
        }
        
        /// Value returned by BACKEND (GET API)
        static func fromServer(_ value: String) -> UserStatus? {
            switch value {
            case "available":
                return .available
            case "busy":
                return .busy
            case "do_not_disturb", "dnd":
                return .doNotDisturb
            default:
                return nil
            }
        }
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchCurrentStatus()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        [availableView, busyView, dndView].forEach {
            $0?.layer.cornerRadius = 8
            $0?.backgroundColor = .clear
        }
    }
    
    // MARK: - Button Actions
    @IBAction func availableButtonTapped(_ sender: Any) {
        confirmStatusChange(.available)
       
    }
    
    @IBAction func busyButtonTapped(_ sender: Any) {
        confirmStatusChange(.busy)
    }
    
    @IBAction func doNotDisturbButtonTapped(_ sender: Any) {
        confirmStatusChange(.doNotDisturb)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - API Call: Update Status
    private func updateStatusOnServer(_ status: UserStatus) {
        self.view.endEditing(true)
        
        let reachability = Reachability()
        guard reachability?.connection == .wifi ||
                reachability?.connection == .cellular else {
            showAlert("Connectly", "No internet connection")
            return
        }
        
        MBProgressHUD.showAdded(to: view, animated: true)
        
        let params: [String: Any] = [
            "status": status.apiValue,
            "app": "iOS"
        ]
        
        NetworkManager.shared.load(
            path: "user/status",
            method: .put,
            params: params
        ) { [weak self] data, _, _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                
                guard let data = data else {
                    self.showAlert("Connectly", "No response from server")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(UpdateStatusModel.self, from: data)
                    
                    if response.success == true {
                        self.updateUI(for: status)
                        
                        // ✅ SUCCESS ALERT
                        self.showAlert(
                            "Status Updated",
                            "Your status has been updated to \(status.displayValue)."
                        )
                        
                    } else {
                        self.showAlert(
                            "Connectly",
                            response.message ?? "Invalid status"
                        )
                    }
                    
                } catch {
                    self.showAlert("Connectly", error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - API Call: Fetch Current Status
    private func fetchCurrentStatus() {
        self.view.endEditing(true)
        
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
                    
                    if let statusString = response.data?.status,
                       let status = UserStatus.fromServer(statusString) {
                        self.updateUI(for: status)
                    }
                    
                } catch {
                    print("❌ Fetch status decode error:", error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Update UI
    private func updateUI(for status: UserStatus) {
        [availableView, busyView, dndView].forEach {
            $0?.backgroundColor = .clear
        }
        
        switch status {
        case .available:
            availableView.backgroundColor = UIColor.systemGreen/*.withAlphaComponent(0.2)*/
        case .busy:
            busyView.backgroundColor = UIColor.systemOrange/*.withAlphaComponent(0.2)*/
        case .doNotDisturb:
            dndView.backgroundColor = UIColor.systemRed/*.withAlphaComponent(0.2)*/
        }
    }
    private func confirmStatusChange(_ status: UserStatus) {
        
        let alert = UIAlertController(
            title: "Confirm Status Change",
            message: "Are you sure you want to change your status to \(status.displayValue)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            self?.updateStatusOnServer(status)
        })
        
        present(alert, animated: true)
    }
    
    
    // MARK: - Alert
    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
