//
//  ForgotPasswordViewController.swift
//  Connectly
//
//  Created by SPSOFT on 19/11/25.
//

import UIKit
import MBProgressHUD

class ForgotPasswordViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!{
        didSet {
            emailTextField.setLeftView()
            emailTextField.delegate = self
            emailTextField.keyboardType = .emailAddress
            emailTextField.autocapitalizationType = .none
            emailTextField.autocorrectionType = .no
            emailTextField.textContentType = .username
            emailTextField.smartInsertDeleteType = .no
            emailTextField.alpha = 0.7
            emailTextField.attributedPlaceholder = NSAttributedString(
                string: "Enter email",
                attributes: [
                    .foregroundColor: UIColor.black
                ]
            )
            
        }
    }
    @IBOutlet weak var otpTextField: UITextField!{
        didSet {
            otpTextField.setLeftView()
            otpTextField.delegate = self
            otpTextField.keyboardType = .emailAddress
            otpTextField.autocapitalizationType = .none
            otpTextField.autocorrectionType = .no
            otpTextField.textContentType = .username
            otpTextField.smartInsertDeleteType = .no
            otpTextField.alpha = 0.7
            otpTextField.attributedPlaceholder = NSAttributedString(
                string: "Enter otp",
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
            newPasswordTextField.passwordRules =
            UITextInputPasswordRules(descriptor: "required: upper, lower, digit; minlength: 6;")
            newPasswordTextField.alpha = 0.7
            newPasswordTextField.attributedPlaceholder = NSAttributedString(
                string: "Enter new password",
                attributes: [
                    .foregroundColor: UIColor.black
                ]
            )
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
            confirmPasswordTextField.passwordRules =
            UITextInputPasswordRules(descriptor: "required: upper, lower, digit; minlength: 6;")
            confirmPasswordTextField.alpha = 0.7
            confirmPasswordTextField.attributedPlaceholder = NSAttributedString(
                string: "Enter confirm password",
                attributes: [
                    .foregroundColor: UIColor.black
                ]
            )
        }
    }
    @IBOutlet weak var forgotpasswordOtpVerificationView: UIView!
    @IBOutlet weak var setPasswordView: UIView!
    
    var isOTPReceived: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial state — both hidden
        forgotpasswordOtpVerificationView.isHidden = true
        setPasswordView.isHidden = true
        
        // ✅ Setup password fields with eye toggle
        setupPasswordFields()
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        clearAllFields()
        
    }
    private func clearAllFields() {
        emailTextField.text = ""
        otpTextField.text = ""
        newPasswordTextField.text = ""
        confirmPasswordTextField.text = ""
        
        // Hide views again
        forgotpasswordOtpVerificationView.isHidden = true
        setPasswordView.isHidden = true
        
        // Reset state
        isOTPReceived = false
        
        // Dismiss keyboard if open
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        switch textField {
        case emailTextField:
            otpTextField.becomeFirstResponder()
        case otpTextField:
            newPasswordTextField.becomeFirstResponder()
        case newPasswordTextField:
            confirmPasswordTextField.becomeFirstResponder()
        case confirmPasswordTextField:
            textField.resignFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        
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
    
    
    // MARK: - Password Field Eye Toggle Setup
    private func setupPasswordFields() {
        configurePasswordField(newPasswordTextField)
        configurePasswordField(confirmPasswordTextField)
    }
    
    private func configurePasswordField(_ textField: UITextField) {
        textField.isSecureTextEntry = true
        
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
        
        // Assign the container view as the
        
        textField.rightView = containerView
        textField.rightViewMode = .always
    }
    
    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        guard let textField = [newPasswordTextField, confirmPasswordTextField]
            .first(where: { ($0?.rightView?.subviews.first as? UIButton) === sender }) else { return }
        
        
        guard let tf = textField else { return }
        
        tf.isSecureTextEntry.toggle()
        let imageName = textField!.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
        
        // Fix cursor jump
        if let text = textField!.text {
            textField!.text = ""
            textField!.insertText(text)
        }
    }
    
    // MARK: - Cancel
    @IBAction func forgotPasswordCancelButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: false)
    }
    
    // MARK: - Submit Email → Send OTP
    @IBAction func forgotPasswordSubmitButton(_ sender: Any) {
        self.otpTextField.text = ""
        if emailTextField.text?.isEmpty == true {
            self.noActionAlertView(title: appTitle, message: "Please enter email address")
        } else if emailTextField.text?.isValidEmail == false {
            self.noActionAlertView(title: appTitle, message: "Please enter valid email address")
        } else {
            let reachability = Reachability()
            if reachability?.connection == .wifi || reachability?.connection == .cellular {
                self.serviceForForgotPassword()
            } else {
                self.noActionAlertView(title: appTitle, message: noInternetMessage)
            }
        }
    }
    
    // MARK: - API → Forgot Password
    func serviceForForgotPassword() {
        self.view.endEditing(true)
        self.startProgressHUD()
        
        let params = ["email": emailTextField.text ?? ""]
        
        NetworkManager.shared.load(path: "auth/forgot-password", method: .post, params: params) { (data, error, response) in
            DispatchQueue.main.async {
                self.stopProgressHUD()
                
                guard response == true else {
                    self.noActionAlertView(title: appTitle, message: "Server error. Please try again.")
                    return
                }
                
                guard let responseData = data else {
                    self.noActionAlertView(title: appTitle, message: "No data received from server.")
                    return
                }
                
                do {
                    let apiResponse = try JSONDecoder().decode(ForgotPasswordModel.self, from: responseData)
                    if apiResponse.statusCode == 200 {
                        self.isOTPReceived = true
                        self.forgotpasswordOtpVerificationView.isHidden = false
                        self.setPasswordView.isHidden = true
                        self.noActionAlertView(title: appTitle, message: "An OTP has been sent to your registered email.")
                    } else {
                        self.noActionAlertView(title: appTitle, message: apiResponse.message ?? "Something went wrong.")
                    }
                } catch {
                    self.noActionAlertView(title: appTitle, message: "Decoding Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Cancel OTP Screen
    @IBAction func forgotOtpCancelButton(_ sender: Any) {
        self.view.endEditing(true)   // dismiss keyboard
        self.forgotpasswordOtpVerificationView.isHidden = true
        
    }
    
    // MARK: - Submit OTP
    @IBAction func forgotOtpSubmitButton(_ sender: Any) {
        newPasswordTextField.text = ""
        confirmPasswordTextField.text = ""
        if otpTextField.text?.isEmpty == true {
            self.noActionAlertView(title: appTitle, message: "Please enter OTP")
        } else {
            let reachability = Reachability()
            if reachability?.connection == .wifi || reachability?.connection == .cellular {
                if isOTPReceived {
                    self.serviceForVerifyOTP()
                } else {
                    self.noActionAlertView(title: appTitle, message: "Please request OTP first.")
                }
            } else {
                self.noActionAlertView(title: appTitle, message: noInternetMessage)
            }
        }
    }
    
    @IBAction func resendOTPForgotPassword(_ sender: Any) {
        if emailTextField.text?.isEmpty == true {
            self.noActionAlertView(title: appTitle, message: "Please enter email address")
            return
        }
        
        if emailTextField.text?.isValidEmail == false {
            self.noActionAlertView(title: appTitle, message: "Please enter valid email address")
            return
        }
        
        let reachability = Reachability()
        if reachability?.connection == .wifi || reachability?.connection == .cellular {
            serviceForResendOTP()
        } else {
            self.noActionAlertView(title: appTitle, message: noInternetMessage)
        }
    }
    
    func serviceForResendOTP() {
        
        self.view.endEditing(true)
        self.startProgressHUD()
        
        let params = ["email": emailTextField.text ?? ""]
        
        NetworkManager.shared.load(path: "auth/forgot-password", method: .post, params: params) { (data, error, response) in
            DispatchQueue.main.async {
                self.stopProgressHUD()
                
                guard let responseData = data else {
                    self.noActionAlertView(title: appTitle, message: "Server error")
                    return
                }
                
                do {
                    let apiResponse = try JSONDecoder().decode(ForgotPasswordModel.self, from: responseData)
                    if apiResponse.statusCode == 200 {
                        self.isOTPReceived = true
                        self.forgotpasswordOtpVerificationView.isHidden = false
                        self.noActionAlertView(title: appTitle, message: "OTP has been resent to your email.")
                    } else {
                        self.noActionAlertView(title: appTitle, message: apiResponse.message ?? "Failed to resend OTP")
                    }
                } catch {
                    self.noActionAlertView(title: appTitle, message: "Decoding Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func serviceForVerifyOTP() {
        self.view.endEditing(true)
        self.startProgressHUD()
        
        let params: [String: Any] = [
            "email": emailTextField.text ?? "",
            "otp": otpTextField.text ?? "",
            "otpType": "forgotPassword"
        ]
        
        NetworkManager.shared.load(path: "auth/forgot-password/verify-otp", method: .post, params: params) { (data, error, response) in
            DispatchQueue.main.async {
                self.stopProgressHUD()
                guard let responseData = data else {
                    self.noActionAlertView(title: appTitle, message: "Server error")
                    return
                }
                
                do {
                    let apiResponse = try JSONDecoder().decode(ForgotPasswordVerifyOtpModel.self, from: responseData)
                    if apiResponse.statusCode == 200 {
                        self.forgotpasswordOtpVerificationView.isHidden = true
                        self.setPasswordView.isHidden = false
                        self.singleActionAlertView(title: appTitle, message: "OTP verified successfully") { _ in }
                    } else {
                        self.noActionAlertView(title: appTitle, message: apiResponse.message ?? "OTP is invalid")
                    }
                } catch {
                    self.noActionAlertView(title: appTitle, message: "Decoding Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @IBAction func setPasswordCancelButton(_ sender: Any) {
        self.setPasswordView.isHidden = true
    }
    
    @IBAction func setPasswordSubmitButton(_ sender: Any) {
        
        // Safely unwrap text
        let newPassword = newPasswordTextField.text ?? "" .trimmingCharacters(in: .whitespacesAndNewlines)
        let confirmPassword = confirmPasswordTextField.text ?? "" .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1️⃣ Check empty fields first
        if newPassword.isEmpty {
            noActionAlertView(title: appTitle, message: "Please enter new password")
            return
        }
        
        if confirmPassword.isEmpty {
            noActionAlertView(title: appTitle, message: "Please enter confirm password")
            return
        }
        
        // 2️⃣ Check minimum length
        if newPassword.count < 6 || confirmPassword.count < 6 {
            noActionAlertView(title: appTitle, message: "Password must be at least 6 characters long.")
            return
        }
        
        // 3️⃣ Check if passwords match
        if newPassword != confirmPassword {
            noActionAlertView(title: appTitle, message: "Passwords do not match")
            return
        }
        
        // 4️⃣ Check internet and call API
        let reachability = Reachability()
        if reachability?.connection == .wifi || reachability?.connection == .cellular {
            serviceForResetPassword()
        } else {
            noActionAlertView(title: appTitle, message: noInternetMessage)
        }
    }
    
    
    func serviceForResetPassword() {
        self.view.endEditing(true)
        self.startProgressHUD()
        
        let params: [String: Any] = [
            "email": emailTextField.text ?? "" .trimmingCharacters(in: .whitespacesAndNewlines),
            "password": newPasswordTextField.text ?? "" .trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        
        NetworkManager.shared.load(path: "auth/reset-password", method: .post, params: params) { (data, error, response) in
            DispatchQueue.main.async {
                self.stopProgressHUD()
                guard let responseData = data else { return }
                
                do {
                    let apiResponse = try JSONDecoder().decode(ResetPasswordModel.self, from: responseData)
                    if apiResponse.statusCode == 200 {
                        self.singleActionAlertView(title: appTitle, message: "Password updated successfully") { result in
                            if result {
                                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as! ViewController
                                self.navigationController?.pushViewController(vc, animated: true)
                            }
                        }
                    } else {
                        self.noActionAlertView(title: appTitle, message: apiResponse.message ?? "")
                    }
                } catch {
                    self.noActionAlertView(title: appTitle, message: error.localizedDescription)
                }
            }
        }
    }
}
