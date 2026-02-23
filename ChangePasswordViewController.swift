//
//  ChangePasswordViewController.swift
//  Connectly
//
//  Created by SPSOFT on 09/12/25.
//

import UIKit
import MBProgressHUD

class ChangePasswordViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var oldPasswordTextField: UITextField!{
        didSet {
            oldPasswordTextField.setLeftView()
            oldPasswordTextField.delegate = self
            oldPasswordTextField.keyboardType = .emailAddress
            oldPasswordTextField.autocapitalizationType = .none
            oldPasswordTextField.autocorrectionType = .no
            oldPasswordTextField.textContentType = .username
            oldPasswordTextField.smartInsertDeleteType = .no
            oldPasswordTextField.alpha = 0.7
            oldPasswordTextField.attributedPlaceholder = NSAttributedString(
                string: "Enter Old Password",
                attributes: [
                    .foregroundColor: UIColor.black
                ]
            )
            
        }
    }
    @IBOutlet weak var newPasswordTextField: UITextField!{
        didSet {
            newPasswordTextField.setLeftView()
            newPasswordTextField.delegate = self
            newPasswordTextField.keyboardType = .emailAddress
            newPasswordTextField.autocapitalizationType = .none
            newPasswordTextField.autocorrectionType = .no
            newPasswordTextField.textContentType = .username
            newPasswordTextField.smartInsertDeleteType = .no
            newPasswordTextField.alpha = 0.7
            newPasswordTextField.attributedPlaceholder = NSAttributedString(
                string: "Enter New Password",
                attributes: [
                    .foregroundColor: UIColor.black
                ]
            )
            newPasswordTextField.passwordRules =
            UITextInputPasswordRules(descriptor: "required: upper, lower, digit; minlength: 6;")
        }
    }
    @IBOutlet weak var confirmPasswordTextField: UITextField!{
        didSet {
            confirmPasswordTextField.setLeftView()
            confirmPasswordTextField.delegate = self
            confirmPasswordTextField.keyboardType = .emailAddress
            confirmPasswordTextField.autocapitalizationType = .none
            confirmPasswordTextField.autocorrectionType = .no
            confirmPasswordTextField.textContentType = .username
            confirmPasswordTextField.smartInsertDeleteType = .no
            confirmPasswordTextField.alpha = 0.7
            confirmPasswordTextField.attributedPlaceholder = NSAttributedString(
                string: "Enter Confirm Password",
                attributes: [
                    .foregroundColor: UIColor.black
                ]
            )
            confirmPasswordTextField.passwordRules =
            UITextInputPasswordRules(descriptor: "required: upper, lower, digit; minlength: 6;")
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPasswordFields()
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        if string.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
            return false
        }
        return true
    }
    
    
    
    // MARK: - Setup
    private func setupPasswordFields() {
        configurePasswordField(oldPasswordTextField)
        configurePasswordField(newPasswordTextField)
        configurePasswordField(confirmPasswordTextField)
    }
    
    private func configurePasswordField(_ textField: UITextField) {
        textField.isSecureTextEntry = true
        
        // Create the eye button
        let eyeButton = UIButton(type: .system)
        eyeButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        eyeButton.tintColor = .systemGray
        eyeButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        eyeButton.addTarget(self, action: #selector(togglePasswordVisibility(_:)), for: .touchUpInside)
        
        // Create container view with padding to move eye left
        let padding: CGFloat = 8
        let containerWidth = eyeButton.frame.width + padding
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: 20))
        containerView.addSubview(eyeButton)
        
        // Center the button vertically inside the container
        eyeButton.center = CGPoint(x: eyeButton.frame.width / 2, y: containerView.bounds.height / 2)
        
        // Assign the container view as the rightView
        textField.rightView = containerView
        textField.rightViewMode = .always
    }
    
    
    // MARK: - Eye Toggle
    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        
        // Find the text field whose rightView contains the tapped button
        guard let textField = [oldPasswordTextField,
                               newPasswordTextField,
                               confirmPasswordTextField]
            .first(where: { ($0?.rightView?.subviews.first as? UIButton) === sender }) else { return }
        
        textField!.isSecureTextEntry.toggle()
        
        let imageName = textField!.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
        
        // Fix cursor jump
        if let text = textField!.text {
            textField!.text = ""
            textField!.insertText(text)
        }
    }
    
    
    // MARK: - Actions
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func changePasswordButton(_ sender: Any) {
        
        // 1️⃣ Ensure all fields are entered
        // Trim spaces just in case
        let oldPassword = oldPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let newPassword = newPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let confirmPassword = confirmPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // 1️⃣ Ensure all fields are entered
        guard !oldPassword.isEmpty,
              !newPassword.isEmpty,
              !confirmPassword.isEmpty else {
            noActionAlertView(title: appTitle, message: "All fields are required")
            return
        }
        
        // 2️⃣ Password length check
        guard newPassword.count >= 6 else {
            noActionAlertView(title: appTitle, message: "Password must be at least 6 characters long.")
            return
        }
        
        // 3️⃣ Old vs new password
        guard oldPassword != newPassword else {
            noActionAlertView(title: appTitle, message: "New password cannot be same as old password")
            return
        }
        
        // 4️⃣ Confirm password matches
        guard newPassword == confirmPassword else {
            noActionAlertView(title: appTitle, message: "New password and confirm password do not match")
            return
        }
        
        // 5️⃣ Internet connectivity
        let reachability = Reachability()
        guard reachability?.connection == .wifi || reachability?.connection == .cellular else {
            noActionAlertView(title: appTitle, message: noInternetMessage)
            return
        }
        
        // 6️⃣ Call API
        serviceForChangePassword(
            oldPassword: oldPassword,
            newPassword: newPassword,
            confirmPassword: confirmPassword
        )
    }
}
// MARK: - Change Password API
extension ChangePasswordViewController {
    
    func serviceForChangePassword(oldPassword: String,
                                  newPassword: String,
                                  confirmPassword: String) {
        self.view.endEditing(true)
        
        startProgressHUD()
        
        let params: [String: Any] = [
            "old_password": oldPassword,
            "new_password": newPassword,
            "confirm_password": confirmPassword,
            "app": "iOS"
        ]
        
        NetworkManager.shared.load(
            path: "profile/change-password",
            method: .put,
            params: params
        ) { [weak self] data, error, success in
            
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.stopProgressHUD()
            }
            
            guard success == true, let data = data else {
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
                    .decode(ChangePasswordModel.self, from: data)
                
                DispatchQueue.main.async {
                    
                    if response.success == true {
                        // ✅ Success → navigate back
                        self.singleActionAlertView(
                            title: appTitle,
                            message: response.message ?? "Password changed successfully"
                        ) { _ in
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        // ❌ Validation error → stay on screen
                        self.noActionAlertView(
                            title: appTitle,
                            message: response.message ?? "Unable to change password"
                        )
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
}
