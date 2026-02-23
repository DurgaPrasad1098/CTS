//
//  SignUpViewController.swift
//  Connectly


import UIKit
import MBProgressHUD
import SDWebImage

class SignUpViewController: UIViewController, OTPVerifyDelegate, UITextFieldDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!{
        didSet {
            nameTextField.setLeftView()
            nameTextField.delegate = self
            nameTextField.keyboardType = .emailAddress
            nameTextField.autocapitalizationType = .none
            nameTextField.autocorrectionType = .no
            nameTextField.textContentType = .username
            nameTextField.smartInsertDeleteType = .no
            nameTextField.alpha = 0.7
            nameTextField.attributedPlaceholder = NSAttributedString(
                string: "Enter Name",
                attributes: [
                    .foregroundColor: UIColor.black
                ]
            )
        }
    }
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
                string: "Enter Email",
                attributes: [
                    .foregroundColor: UIColor.black
                ]
            )
        }
    }
    @IBOutlet weak var passwordTextField: UITextField!{
        didSet {
            passwordTextField.setLeftView()
            passwordTextField.delegate = self
            passwordTextField.keyboardType = .emailAddress
            passwordTextField.autocapitalizationType = .none
            passwordTextField.autocorrectionType = .no
            passwordTextField.textContentType = .username
            passwordTextField.smartInsertDeleteType = .no
            passwordTextField.alpha = 0.7
            passwordTextField.attributedPlaceholder = NSAttributedString(
                string: "Enter Password",
                attributes: [
                    .foregroundColor: UIColor.black
                ]
            )
        }
    }
    @IBOutlet weak var confirmPasswordTextField: UITextField! {
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
        }
    }
    
    @IBOutlet weak var editProfileImage: UIImageView!
    
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var otpVerificationView: UIView!
    @IBOutlet weak var otpTextField: UITextField!{
        didSet {
            otpTextField.setLeftView()
            otpTextField.delegate = self
            otpTextField.keyboardType = .emailAddress
            otpTextField.autocapitalizationType = .none
            otpTextField.autocorrectionType = .no
            otpTextField.textContentType = .username
            otpTextField.smartInsertDeleteType = .no
        }
    }
    
    @IBOutlet weak var signInButton: UIButton!
    
    // MARK: - Variables
    var imagePicker: ImagePicker!
    var profile_image_base64: String = ""
    var verifiedUserID: Int?
    var inviteID: Int?
    
    // ✅ Backend-safe timezone
    private var timezone: String = ""
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        otpVerificationView.isHidden = true
        setupUI()
        setupProfileTap()
        setupTimeZoneObserver()
        self.view.endEditing(true)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Timezone
    private func setupTimeZoneObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemTimeZoneDidChange),
            name: NSNotification.Name.NSSystemTimeZoneDidChange,
            object: nil
        )
        updateUserTimeZone()
    }
    
    private func updateUserTimeZone() {
        timezone = TimeZone.current.identifier
        print("🌍 Timezone:", timezone)
    }
    
    @objc private func systemTimeZoneDidChange(_ notification: Notification) {
        updateUserTimeZone()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.isUserInteractionEnabled = true
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.borderColor = UIColor.black.cgColor
        
        
    }
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        if string.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
            return false
        }
        return true
    }
    
    
    private func setupProfileTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectProfileImage))
        //        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tap)
    }
    
    // MARK: - Image Picker
    @objc private func selectProfileImage() {
        imagePicker = ImagePicker(presentationController: self, delegate: self)
        imagePicker.present(from: profileImageView)
    }
    
    @IBAction func imageUploadButton(_ sender: Any) {
        imagePicker = ImagePicker(presentationController: self, delegate: self)
        imagePicker.present(from: self.view)
    }
    
    @IBAction func editImageUploadButton(_ sender: Any) {
        imagePicker = ImagePicker(presentationController: self, delegate: self)
        imagePicker.present(from: self.view)
        
    }
    
    // MARK: - OTP Delegate
    func otpVerifiedSuccessfully(id: Int, email: String) {
        DispatchQueue.main.async {
            self.verifiedUserID = id
            self.emailTextField.text = email
        }
    }
    
    // MARK: - Actions
    @IBAction func resendOtpButton(_ sender: Any) {
        serviceForResendOTP()
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        otpVerificationView.isHidden = true
    }
    
    @IBAction func submitButton(_ sender: Any) {
        guard let otp = otpTextField.text, !otp.isEmpty else {
            noActionAlertView(title: appTitle, message: "Please enter OTP")
            return
        }
        serviceForVerifyOTP()
    }
    
    @IBAction func signInButton(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }
    
    // MARK: - Sign Up
    @IBAction func signUpButtonTapped(_ sender: Any) {
        
        // Trim values first
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let pwd = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cpwd = confirmPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // 1️⃣ Name validation
        guard !name.isEmpty else {
            noActionAlertView(title: appTitle, message: "Please enter your name")
            return
        }
        
        // 2️⃣ Email validation
        guard !email.isEmpty else {
            noActionAlertView(title: appTitle, message: "Please enter email")
            return
        }
        
        guard email.isValidEmail else {
            noActionAlertView(title: appTitle, message: "Invalid email")
            return
        }
        
        // 3️⃣ Password validation
        guard !pwd.isEmpty else {
            noActionAlertView(title: appTitle, message: "Enter password")
            return
        }
        
        // 4️⃣ Confirm password validation
        guard !cpwd.isEmpty else {
            noActionAlertView(title: appTitle, message: "Confirm password")
            return
        }
        
        // 5️⃣ Match password
        guard pwd == cpwd else {
            noActionAlertView(title: appTitle, message: "Passwords do not match")
            return
        }
        
        // ✅ All validations passed
        // Call signup API here
        
        // ✅ Network Reachability Check
        let reachability = Reachability() // Network reachability object
        if reachability?.connection == .wifi ||
            reachability?.connection == .cellular {
            
            serviceForRegisterUser(name: name, email: email, password: pwd)
            
        } else {
            noActionAlertView(title: appTitle, message: "No internet connection")
        }
    }
    
    
    
    // MARK: - SERVICES
    
    func serviceForRegisterUser(name: String, email: String, password: String) {
        self.view.endEditing(true)
        
        startProgressHUD()
        
        let params: [String: Any] = [
            "name": name,
            "email": email,
            "password": password,
            "timezone": timezone,
            "profile_image_base64": profile_image_base64
        ]
        print(params)
        print("📸 Image Base64 Empty:", profile_image_base64.isEmpty)
        
        NetworkManager.shared.load(path: "auth/signup", method: .post, params: params) { data, _, success in
            
            DispatchQueue.main.async {
                self.stopProgressHUD()
                
                guard success == true, let data = data else {
                    self.noActionAlertView(title: appTitle, message: "Signup failed")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(SignUpModel.self, from: data)
                    if response.statusCode == 200 {
                        self.noActionAlertView(title: appTitle, message: "OTP sent to your email")
                        self.otpVerificationView.isHidden = false
                    } else {
                        self.noActionAlertView(title: appTitle, message: response.message ?? "Signup failed")
                    }
                } catch {
                    self.noActionAlertView(title: appTitle, message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Verify OTP
    func serviceForVerifyOTP() {
        self.view.endEditing(true)
        
        startProgressHUD()
        
        let params: [String: Any] = [
            "email": emailTextField.text ?? "",
            "otp": otpTextField.text ?? "",
            "otpType": "register"
        ]
        
        NetworkManager.shared.load(path: "auth/signup/verify-otp", method: .post, params: params) { data, _, success in
            
            DispatchQueue.main.async {
                self.stopProgressHUD()
                
                guard success == true, let data = data else {
                    self.noActionAlertView(title: appTitle, message: "Verification failed")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(VerifyOTPModel.self, from: data)
                    print(response)
                    if response.statusCode == 200 {
                        self.singleActionAlertView(title: appTitle, message: "User registered successfully") { _ in
                            let vc = UIStoryboard(name: "Main", bundle: nil)
                                .instantiateViewController(withIdentifier: "ViewController") as! ViewController
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    } else {
                        self.noActionAlertView(title: appTitle, message: response.message ?? "Invalid OTP")
                    }
                } catch {
                    self.noActionAlertView(title: appTitle, message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Resend OTP
    func serviceForResendOTP() {
        self.view.endEditing(true)
        
        startProgressHUD()
        
        let params: [String: Any] = [
            "email": emailTextField.text ?? "",
            "otpType": "register"
        ]
        
        NetworkManager.shared.load(path: "auth/signup/resend-otp", method: .post, params: params) { data, _, success in
            
            DispatchQueue.main.async {
                self.stopProgressHUD()
                
                guard success == true, let data = data else {
                    self.noActionAlertView(title: appTitle, message: "Failed to resend OTP")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(ResendOtpModel.self, from: data)
                    self.noActionAlertView(title: appTitle, message: response.message ?? "OTP resent")
                } catch {
                    self.noActionAlertView(title: appTitle, message: error.localizedDescription)
                }
            }
        }
    }
}
extension SignUpViewController: ImagePickerDelegate {
    
    func didSelect(image: UIImage?) {
        guard let image = image else { return }
        
        DispatchQueue.main.async {
            self.profileImageView.image = image
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.6) else { return }
        
        // ✅ CORRECT Base64 conversion
        self.profile_image_base64 = imageData.base64EncodedString()
        
        print("✅ Image Base64 Size:", self.profile_image_base64.count)
    }
}
extension String {
    var isValidEmail: Bool {
        NSPredicate(
            format: "SELF MATCHES %@",
            "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        ).evaluate(with: self)
    }
}
