//
//  CreateGroupsViewController.swift
//  Connectly

//
import UIKit
import MBProgressHUD
import SDWebImage

// MARK: - Delegate
protocol CreateGroupDelegate: AnyObject {
    func didCreateGroupSuccessfully()
}

class CreateGroupsViewController: UIViewController,
                                  UITextFieldDelegate,
                                  UITextViewDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var selectedGroupIcon: UIImageView!
    @IBOutlet weak var groupNameTextField: UITextField!{
        didSet {
            groupNameTextField.setLeftView()
            groupNameTextField.delegate = self
            groupNameTextField.keyboardType = .default
            groupNameTextField.autocapitalizationType = .words
            
            groupNameTextField.autocorrectionType = .yes
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
    
    // MARK: - Properties
    weak var delegate: CreateGroupDelegate?
    
    private var imagePicker: ImagePicker!
    private var group_icon_base64 = ""
    private var profileImageURL: URL?
    private var profileImageName = ""
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupProfileImageTap()
        setupKeyboard()
        setupTextViewPlaceholder()
        groupDescriptionTextView.layer.borderWidth = 1
        groupDescriptionTextView.layer.borderColor = UIColor.black.cgColor
        
    }
    
    // 🔥 KEYBOARD OPENS HERE
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        groupNameTextField.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        selectedGroupIcon.layer.cornerRadius = selectedGroupIcon.frame.height / 2
        selectedGroupIcon.clipsToBounds = true
        selectedGroupIcon.isUserInteractionEnabled = true
        selectedGroupIcon.layer.borderWidth = 1
        selectedGroupIcon.layer.borderColor = UIColor.black.cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    
    // MARK: - Keyboard Setup
    private func setupKeyboard() {
        groupNameTextField.delegate = self
        groupDescriptionTextView.delegate = self
        
        groupNameTextField.isUserInteractionEnabled = true
        groupDescriptionTextView.isEditable = true
        groupDescriptionTextView.isSelectable = true
    }
    
    // MARK: - UITextView Placeholder
    private func setupTextViewPlaceholder() {
        groupDescriptionTextView.text = "Enter group description"
        groupDescriptionTextView.textColor = .lightGray
    }
    
    // MARK: - Image Tap
    private func setupProfileImageTap() {
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(selectProfileImage)
        )
        selectedGroupIcon.isUserInteractionEnabled = true
        selectedGroupIcon.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    @objc func selectProfileImage() {
        imagePicker = ImagePicker(
            presentationController: self,
            delegate: self
        )
        imagePicker.present(from: selectedGroupIcon)
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func selectedGroupIconButton(_ sender: Any) {
        selectProfileImage()
    }
    
    @IBAction func createGroupButton(_ sender: Any) {
        let reachability = Reachability()
        
        guard reachability?.connection == .wifi ||
                reachability?.connection == .cellular else {
            noActionAlertView(title: appTitle, message: noInternetMessage)
            return
        }
        
        createGroup()
    }
    
    // MARK: - API Call
    private func createGroup() {
        
        self.view.endEditing(true)
        
        guard
            let groupName = groupNameTextField.text, !groupName.isEmpty,
            let groupDescription = groupDescriptionTextView.text
//            !groupDescription.isEmpty,
//            groupDescriptionTextView.textColor != .lightGray
       else {
//            showSimpleAlert(
//                title: appTitle,
//                message: "Please fill all fields."
         //   )
            return
        }
        
        
        var params: [String: Any] = [
            "group_name": groupName,
            "group_description": groupDescription
        ]
        if !group_icon_base64.isEmpty {
            params["group_icon_base64"] = group_icon_base64
        }
        
        MBProgressHUD.showAdded(to: view, animated: true)
        
        NetworkManager.shared.load(
            path: "groups/create",
            method: .post,
            params: params
        ) { [weak self] data, error, response in
            
            guard let self else { return }
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
            
            guard response == true else {
                self.showSimpleAlert(
                    title: "Error",
                    message: error?.localizedDescription ?? "Network Error"
                )
                return
            }
            
            guard let responseData = data else {
                self.showSimpleAlert(
                    title: "Error",
                    message: "Empty server response."
                )
                return
            }
            
            do {
                let apiResponse = try JSONDecoder()
                    .decode(CreateGroupModel.self, from: responseData)
                
                DispatchQueue.main.async {
                    if apiResponse.statusCode == 200 || apiResponse.success == true {
                        
                        self.singleActionAlertView(
                            title: "Group Created",
                            message: apiResponse.message ?? "Success"
                        ) { _ in
                            self.delegate?.didCreateGroupSuccessfully()
                            
                            let vc = UIStoryboard(
                                name: "Main",
                                bundle: nil
                            ).instantiateViewController(
                                withIdentifier: "GroupsViewController"
                            ) as! GroupsViewController
                            
                            self.navigationController?
                                .pushViewController(vc, animated: true)
                        }
                        
                    } else {
                        self.showSimpleAlert(
                            title: "Error",
                            message: apiResponse.message ??
                            "Failed to create group."
                        )
                    }
                }
                
            } catch {
                self.showSimpleAlert(
                    title: "Decoding Error",
                    message: error.localizedDescription
                )
            }
        }
    }
}

// MARK: - ImagePickerDelegate
extension CreateGroupsViewController: ImagePickerDelegate {
    
    func didSelect(image: UIImage?) {
        guard let img = image else { return }
        
        selectedGroupIcon.image = img
        
        guard let imgData = img.jpegData(compressionQuality: 0.4) else {
            return
        }
        
        profileImageName = random(length: 12)
        
        let docs = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        )[0] as NSString
        
        let filePath = docs.appendingPathComponent(
            "\(profileImageName).jpeg"
        )
        
        FileManager.default.createFile(
            atPath: filePath,
            contents: imgData,
            attributes: nil
        )
        
        profileImageURL = URL(fileURLWithPath: filePath)
        
        if let base64 = getBase64(from: profileImageURL) {
            group_icon_base64 = base64
        }
    }
    
    private func random(length: Int) -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
        return String(
            (0..<length).compactMap { _ in chars.randomElement() }
        )
    }
    
    private func getBase64(from url: URL?) -> String? {
        guard let url,
              let data = try? Data(contentsOf: url)
        else { return nil }
        
        return data.base64EncodedString()
    }
}

// MARK: - UITextView Delegate
extension CreateGroupsViewController {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            setupTextViewPlaceholder()
        }
    }
    
    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

// MARK: - UITextField Delegate
extension CreateGroupsViewController {
    
    func textFieldShouldReturn(
        _ textField: UITextField
    ) -> Bool {
        
        groupDescriptionTextView.becomeFirstResponder()
        return true
    }
}

// MARK: - Alerts
extension CreateGroupsViewController {
    
    func showSimpleAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(
                UIAlertAction(title: "OK", style: .default)
            )
            self.present(alert, animated: true)
        }
    }
}
