//
//  UpdateProfileViewController.swift
//  Connectly
//
//  Created by SPSOFT on 09/12/25
//
import UIKit
import MBProgressHUD

class UpdateProfileViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var profile: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!{
        didSet {
            nameTextField.setLeftView()
            nameTextField.delegate = self
            nameTextField.keyboardType = .default
            nameTextField.autocapitalizationType = .none
            nameTextField.autocorrectionType = .no
            nameTextField.textContentType = .username
            nameTextField.smartInsertDeleteType = .no
            //nameTextField.alpha = 0.7
            nameTextField.attributedPlaceholder = NSAttributedString(
                string: "Enter name",
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
            emailTextField.textColor = .black
            emailTextField.backgroundColor = .lightGray
            emailTextField.alpha = 0.7
            emailTextField.attributedPlaceholder = NSAttributedString(
                string: "Enter email",
                attributes: [
                    .foregroundColor: UIColor.black
                ]
            )
        }
        
    }
    
    // MARK: - Properties
    var userID: Int?
    var name: String?
    var email: String?
    var profileImageURLString: String?
    var imagePicker: ImagePicker!
    
    // Base64 ONLY when user selects new image
    private var profileImageBase64: String = ""
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        
        nameTextField.delegate = self
        emailTextField.delegate = self
        profile.layer.cornerRadius = profile.frame.height / 2
        profile.clipsToBounds = true
        profile.isUserInteractionEnabled = true
        profile.layer.borderWidth = 1
        profile.layer.borderColor = UIColor.black.cgColor
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectProfileImage))
        profile.addGestureRecognizer(tap)
        nameTextField.text = name
        emailTextField.text = email
        
        
        if let path = profileImageURLString,
           let url = URL(string: fullImageURL(path)) {
            loadProfileImage(from: url)
        } else {
            profile.image = UIImage(named: "defaultProfile")
        }
    }
    
    // MARK: - Image Helpers
    private func fullImageURL(_ path: String) -> String {
        if path.hasPrefix("http") { return path }
        return "http://192.168.5.39:8000" + path
    }
    
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data,
                  let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.profile.image = image
            }
        }.resume()
    }
    
    // MARK: - Image Picker
    @objc private func selectProfileImage() {
        imagePicker = ImagePicker(presentationController: self, delegate: self)
        imagePicker.present(from: profile)
    }
    
    // MARK: - Actions
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func updateProfileButton(_ sender: Any) {
        
        // ✅ Network Reachability Check
        let reachability = Reachability() // Network reachability object
        
        if reachability?.connection == .wifi ||
            reachability?.connection == .cellular {
            
            validateAndUpdateProfile()
            
        } else {
            noActionAlertView(
                title: appTitle,
                message: "No internet connection. Please check your network."
            )
        }
    }
    
    
    // MARK: - Validation
    private func validateAndUpdateProfile() {
        
        guard let name = nameTextField.text, !name.isEmpty else {
            showAlert(title: "Connectly", message: "Please enter name")
            return
        }
        
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(title: "Connectly", message: "Please enter email")
            return
        }
        
        updateProfileOnServer()
    }
    
    //    // MARK: - API Call
    //    private func updateProfileOnServer() {
    //
    //        MBProgressHUD.showAdded(to: view, animated: true)
    //
    //        // ✅ URL or Base64 (never both)
    //        let imageParam = profileImageBase64.isEmpty
    //            ? (profileImageURLString ?? "")
    //            : profileImageBase64
    //
    //        let params: [String: Any] = [
    //            "user_id": userID ?? 0,
    //            "name": nameTextField.text ?? "",
    //            "email": emailTextField.text ?? "",
    //            "profile_image_base64": imageParam,
    //            "app": "iOS"
    //        ]
    //
    //        NetworkManager.shared.load(
    //            path: "profile/update",
    //            method: .put,
    //            params: params
    //        ) { [weak self] data, error, success in
    //
    //            DispatchQueue.main.async {
    //                MBProgressHUD.hide(for: self?.view ?? UIView(), animated: true)
    //
    //                guard success == true, let data = data else {
    //                    self?.showAlert(
    //                        title: "Connectly",
    //                        message: error?.localizedDescription ?? "Server error"
    //                    )
    //                    return
    //                }
    //
    //                do {
    //                    let response = try JSONDecoder().decode(UpdateProfileModel.self, from: data)
    //
    //                    if response.success == true {
    //
    //                        Appstorage.name = self?.nameTextField.text ?? Appstorage.name
    //                        Appstorage.emailId = self?.emailTextField.text ?? Appstorage.emailId
    //                        Appstorage.profileImage = response.data?.profileImage
    //
    //                        self?.showAlert(
    //                            title: "Connectly",
    //                            message: response.message ?? "Profile updated successfully"
    //                        ) {
    //                            self?.navigationController?.popViewController(animated: true)
    //                        }
    //
    //                    } else {
    //                        self?.showAlert(
    //                            title: "Connectly",
    //                            message: response.message ?? "Profile update failed"
    //                        )
    //                    }
    //
    //                } catch {
    //                    self?.showAlert(
    //                        title: "Connectly",
    //                        message: error.localizedDescription
    //                    )
    //                }
    //            }
    //        }
    //    }
    private func updateProfileOnServer() {
        
        MBProgressHUD.showAdded(to: view, animated: true)
        
        // ✅ Base params (name & email always update)
        var params: [String: Any] = [
            "user_id": userID ?? 0,
            "name": nameTextField.text ?? "",
            "email": emailTextField.text ?? "",
            "app": "iOS"
        ]
        
        // ✅ ONLY send image if user selected a new one
        if !profileImageBase64.isEmpty {
            params["profile_image_base64"] = profileImageBase64
        }
        
        NetworkManager.shared.load(
            path: "profile/update",
            method: .put,
            params: params
        ) { [weak self] data, error, success in
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self?.view ?? UIView(), animated: true)
                
                guard success == true, let data = data else {
                    self?.showAlert(
                        title: "Connectly",
                        message: error?.localizedDescription ?? "Server error"
                    )
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(UpdateProfileModel.self, from: data)
                    
                    if response.success == true {
                        
                        // ✅ Update only changed fields
                        Appstorage.name = self?.nameTextField.text ?? Appstorage.name
                        Appstorage.emailId = self?.emailTextField.text ?? Appstorage.emailId
                        
                        // ✅ Image updates only if backend sends new one
                        if let newImage = response.data?.profileImage {
                            Appstorage.profileImage = newImage
                            self?.profileImageURLString = newImage
                        }
                        
                        self?.showAlert(
                            title: "Connectly",
                            message: response.message ?? "Profile updated successfully"
                        ) {
                            self?.navigationController?.popViewController(animated: true)
                        }
                        
                    } else {
                        self?.showAlert(
                            title: "Connectly",
                            message: response.message ?? "Profile update failed"
                        )
                    }
                    
                } catch {
                    self?.showAlert(
                        title: "Connectly",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    
    
    // MARK: - Alert
    private func showAlert(
        title: String,
        message: String,
        completion: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

extension UpdateProfileViewController: ImagePickerDelegate {
    
    func didSelect(image: UIImage?) {
        guard let image = image else { return }
        
        profile.image = image
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            let resizedImage = image.resized(maxWidth: 600)
            
            guard let jpegData = resizedImage.jpegData(compressionQuality: 0.6) else { return }
            
            let base64String = jpegData.base64EncodedString()
            
            DispatchQueue.main.async {
                self.profileImageBase64 = base64String
            }
        }
    }
}
extension UIImage {
    
    func resized(maxWidth: CGFloat) -> UIImage {
        guard size.width > maxWidth else { return self }
        
        let scale = maxWidth / size.width
        let newHeight = size.height * scale
        let newSize = CGSize(width: maxWidth, height: newHeight)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
