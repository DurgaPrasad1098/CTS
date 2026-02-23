//
//  ViewController.swift
//  Connectly
//
//  Created by SPSOFT on 17/11/25.



import UIKit
import MBProgressHUD

class ViewController: UIViewController, UITextFieldDelegate {
    

    
    // MARK: - IBOutlets
    @IBOutlet weak var emailTextField: UITextField! {
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
                string: "Enter Email",
                attributes: [
                    .foregroundColor: UIColor.black
                ]
            )
        }
    }
    
    @IBOutlet weak var passwordTextField: UITextField! {
        didSet {
            passwordTextField.setLeftView()
            passwordTextField.delegate = self
            passwordTextField.isSecureTextEntry = true
            passwordTextField.autocapitalizationType = .none
            passwordTextField.autocorrectionType = .no
            passwordTextField.textContentType = .password
            passwordTextField.smartInsertDeleteType = .no
            passwordTextField.alpha = 0.7
            passwordTextField.attributedPlaceholder = NSAttributedString(
                string: "Enter Password",
                attributes: [
                    .foregroundColor: UIColor.black
                ]
            )
            passwordTextField.passwordRules =
            UITextInputPasswordRules(descriptor: "required: upper, lower, digit; minlength: 6;")
            
        
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            //print("TextField should begin editing method called")
            return true
        }
        
        func textFieldShouldClear(_ textField: UITextField) -> Bool {
            //print("TextField should clear method called")
            return true
        }
        
        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            //print("TextField should end editing method called")
            return true
        }
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            print("TextField should return method called")
//            textField.resignFirstResponder()
            return true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        // Reset email and password fields every time
        emailTextField.text = ""
        passwordTextField.text = ""
        //        emailTextField.text = UserDefaults.standard.string(forKey: "lastUsedEmail")
        //        passwordTextField.text = UserDefaults.standard.string(forKey: "lastUsedPassword")
        
    }
   
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        if string.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
            return false
        }
        return true
    }
    
    
    // MARK: - Actions
    @IBAction func signinButtonTapped(_ sender: UIButton) {
        
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? "" .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // ✅ Both empty
        if email.isEmpty && password.isEmpty {
            noActionAlertView(title: appTitle,
                              message: "Please enter email & password fields.")
            return
        }
        
        // ✅ Email empty
        if email.isEmpty {
            noActionAlertView(title: appTitle,
                              message: "Please enter email.")
            return
        }
        
        // ✅ Invalid email
        if !email.isValidEmail {
            noActionAlertView(title: appTitle,
                              message: "Please enter a valid email address.")
            return
        }
        
        // ✅ Password empty
        if password.isEmpty {
            noActionAlertView(title: appTitle,
                              message: "Please enter password.")
            return
        }
        
        // ✅ Password length
        if password.count < 6 {
            noActionAlertView(title: appTitle,
                              message: "Password must be at least 6 characters long.")
            return
        }
        
        
        
        
        // Save credentials
        UserDefaults.standard.set(email, forKey: "lastUsedEmail")
        UserDefaults.standard.set(password, forKey: "lastUsedPassword")
        
        // Reachability Check
        let reachability = Reachability() // Network reachability object
        if reachability?.connection == .wifi ||
            reachability?.connection == .cellular {
            
            serviceForLogin()
            
        } else {
            noActionAlertView(title: appTitle, message: noInternetMessage)
        }
    }
    
    @IBAction func forgotPasswordButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        if let vc = storyboard.instantiateViewController(
            withIdentifier: "ForgotPasswordViewController"
        ) as? ForgotPasswordViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func signUpButton(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        if let vc = storyboard.instantiateViewController(
            withIdentifier: "SignUpViewController"
        ) as? SignUpViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - Login API
    private func serviceForLogin() {
        
        self.view.endEditing(true)
        startProgressHUD()
        
        guard let email = emailTextField.text,
              let password = passwordTextField.text else {
            stopProgressHUD()
            return
        }
        
        let params: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        NetworkManager.shared.load(
            path: "auth/signin",
            method: .post,
            params: params
        ) { [weak self] data, error, success in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.stopProgressHUD()
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.noActionAlertView(title: "Error", message: error.localizedDescription)
                }
                return
            }
            
            guard success == true, let data else {
                DispatchQueue.main.async {
                    self.noActionAlertView(title: "Error", message: "Login failed.")
                }
                return
            }
            
            do {
                let response = try JSONDecoder().decode(SignInModel.self, from: data)
                
                DispatchQueue.main.async {
                    if response.statusCode == 200, let user = response.data {
                        
                        Appstorage.accessToken = user.accessToken ?? ""
                        Appstorage.profileImage = user.profileImage ?? ""
                        Appstorage.name = user.name ?? ""
                        Appstorage.emailId = user.email ?? ""
                        Appstorage.userID = user.userID ?? 0
                        
                        let storyboard = UIStoryboard(name: "Main", bundle: .main)
                        if let vc = storyboard.instantiateViewController(
                            withIdentifier: "GroupsViewController"
                        ) as? GroupsViewController {
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                        
                    } else {
                        self.noActionAlertView(
                            title: "Error",
                            message: response.message ?? "Login failed"
                        )
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.noActionAlertView(
                        title: "Error",
                        message: "Something went wrong. Please try again."
                    )
                }
            }
        }
    }
}

// MARK: - HUD
extension UIViewController {
    
    func startProgressHUD() {
        DispatchQueue.main.async {
            MBProgressHUD.showAdded(to: self.view, animated: true)
                .label.text = "Loading..."
        }
    }
    
    func stopProgressHUD() {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
}

// MARK: - UITextField Padding
extension UITextField {
    func setLeftView() {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 15))
        leftView = paddingView
        leftViewMode = .always
    }
}
