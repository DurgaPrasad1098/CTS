//
//  AvailableTimingsViewController.swift
//  Connectly
//
//  Created by SPSOFT on 09/12/25.

//
import UIKit
import MBProgressHUD

class AvailableTimingsViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var selectFromTimeTextField: UITextField!{
        didSet {
            selectFromTimeTextField.setLeftView()
            selectFromTimeTextField.delegate = self
            selectFromTimeTextField.keyboardType = .emailAddress
            selectFromTimeTextField.autocapitalizationType = .none
            selectFromTimeTextField.autocorrectionType = .no
            selectFromTimeTextField.textContentType = .username
            selectFromTimeTextField.smartInsertDeleteType = .no
        }
    }
    
    @IBOutlet weak var selectToTimeTextField: UITextField!{
        didSet {
            selectToTimeTextField.setLeftView()
            selectToTimeTextField.delegate = self
            selectToTimeTextField.keyboardType = .emailAddress
            selectToTimeTextField.autocapitalizationType = .none
            selectToTimeTextField.autocorrectionType = .no
            selectToTimeTextField.textContentType = .username
            selectToTimeTextField.smartInsertDeleteType = .no
        }
    }
    @IBOutlet weak var availableTimeTableView: UITableView!
    @IBOutlet weak var selectTimingView: UIView!
    
    // MARK: - Variables
    private var availableTimings: [GetDatum] = []
    private var fromDate: Date?
    private var toDate: Date?
    
    private let fromPicker = UIDatePicker()
    private let toPicker = UIDatePicker()
    
    // MARK: - Empty State Label
    private let emptyAvailableTimingsLabel: UILabel = {
        let label = UILabel()
        label.text = "No available timings yet.\nTap 'add' to add your first timing."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .gray
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupDatePickers()
        fetchAvailableTimings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    // MARK: - UI Setup
    private func setupUI() {
        selectTimingView.isHidden = true
    }
    
    private func setupTableView() {
        availableTimeTableView.delegate = self
        availableTimeTableView.dataSource = self
        availableTimeTableView.tableFooterView = UIView()
    }
    
    private func makeToolbar(selector: Selector) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: selector)
        
        toolbar.items = [flex, done]
        return toolbar
    }
    
    private func setupDatePickers() {
        let now = Date()
        
        fromPicker.datePickerMode = .dateAndTime
        fromPicker.preferredDatePickerStyle = .wheels
        fromPicker.resignFirstResponder()
        fromPicker.minimumDate = now
        fromPicker.endEditing(true)
        selectFromTimeTextField.inputView = fromPicker
        selectFromTimeTextField.inputAccessoryView = makeToolbar(selector: #selector(fromDoneTapped))
        selectFromTimeTextField.resignFirstResponder()
        
        selectFromTimeTextField.alpha = 0.7
        selectFromTimeTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter from Date & Time",
            attributes: [
                .foregroundColor: UIColor.black
            ]
        )
        
        toPicker.datePickerMode = .dateAndTime
        toPicker.preferredDatePickerStyle = .wheels
        toPicker.minimumDate = now
        toPicker.resignFirstResponder()
        toPicker.endEditing(true)
        selectToTimeTextField.inputView = toPicker
        selectToTimeTextField.resignFirstResponder()
        selectToTimeTextField.inputAccessoryView = makeToolbar(selector: #selector(toDoneTapped))
        selectToTimeTextField.alpha = 0.7
        selectToTimeTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter To Date & Time",
            attributes: [
                .foregroundColor: UIColor.black
            ]
        )
    }
    
    // MARK: - Actions
    @IBAction func addAvailableTimeButtonTapped(_ sender: UIButton) {
        selectTimingView.isHidden = false
    }
    
    @IBAction func backToAvailableButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        guard let fromDate, let toDate else {
            noActionAlertView(title: appTitle, message: "Please select From and To time")
            return
        }
        
        if toDate <= fromDate {
            noActionAlertView(title: appTitle, message: "To time must be after From time")
            return
        }
        
        let reachability = Reachability()
        guard reachability?.connection == .wifi || reachability?.connection == .cellular else {
            noActionAlertView(title: appTitle, message: noInternetMessage)
            return
        }
        
        
        addAvailableTiming(from: fromDate, to: toDate)
        
    }
    
    // MARK: - DELETE API
    private func serviceForDeleteAvailability(id: Int?, indexPath: IndexPath) {
        guard let id else { return }
        
        startProgressHUD()
        
        NetworkManager.shared.load(
            path: "user/availability/\(id)",
            method: .delete,
            params: [:]
            
        ) { [weak self] _, _, success in
            guard let self else { return }
            DispatchQueue.main.async {
                self.stopProgressHUD()
                if success == true {
                    self.availableTimings.remove(at: indexPath.row)
                    self.availableTimeTableView.deleteRows(at: [indexPath], with: .automatic)
                    self.updateEmptyState()
                }
            }
        }
    }
    
    private func showDeleteConfirmation(id: Int?, indexPath: IndexPath) {
        let alert = UIAlertController(title: appTitle,
                                      message: "Are you sure you want to delete this timing?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.serviceForDeleteAvailability(id: id, indexPath: indexPath)
        })
        present(alert, animated: true)
    }
    
    // MARK: - POST API
    private func addAvailableTiming(from: Date, to: Date) {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.label.text = "Adding availability..."
        
        let params: [String: Any] = [
            "from_datetime": backendFormatter().string(from: from),
            "to_datetime": backendFormatter().string(from: to)
        ]
        
        NetworkManager.shared.load(
            path: "user/availability",
            method: .post,
            params: params
        ) { [weak self] data, error, success in
            guard let self else { return }
            DispatchQueue.main.async { hud.hide(animated: true) }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.noActionAlertView(title: appTitle, message: error.localizedDescription)
                }
                return
            }
            
            guard success == true, let data else {
                DispatchQueue.main.async {
                    self.noActionAlertView(title: appTitle, message: "Something went wrong")
                }
                return
            }
            
            do {
                let response = try JSONDecoder().decode(AvailableTimingModel.self, from: data)
                DispatchQueue.main.async {
                    if response.statusCode == 200 {
                        self.singleActionAlertView(title: appTitle,
                                                   message: response.message ?? "Availability added successfully") { _ in
                            self.fetchAvailableTimings()
                            self.resetTimingView()
                        }
                    } else {
                        self.noActionAlertView(title: appTitle, message: response.message ?? "Failed to add availability")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.noActionAlertView(title: appTitle, message: "Invalid server response")
                }
            }
        }
    }
    
    // MARK: - GET API
    private func fetchAvailableTimings() {
        startProgressHUD()
        
        NetworkManager.shared.load(
            path: "user/availability",
            method: .get,
            params: [:]
        ) { [weak self] data, error, success in
            guard let self else { return }
            DispatchQueue.main.async { self.stopProgressHUD() }
            
            if let error = error {
                DispatchQueue.main.async { self.noActionAlertView(title: appTitle, message: error.localizedDescription) }
                return
            }
            
            guard success == true, let data else { return }
            
            do {
                let response = try JSONDecoder().decode(GetAvailableTimingModel.self, from: data)
                
                var timings = response.data ?? []
                
                // 🔥 SORT DESCENDING BY from_datetime
                timings.sort {
                    let date1 = $0.fromDatetime?.backendToDate() ?? Date.distantPast
                    let date2 = $1.fromDatetime?.backendToDate() ?? Date.distantPast
                    return date1 < date2   // DESCENDING
                }
                
                self.availableTimings = timings
                
                DispatchQueue.main.async {
                    self.availableTimeTableView.reloadData()
                    self.updateEmptyState()
                }
            } catch {
                print("❌ Decode Error:", error)
            }
            
        }
    }
    
    // MARK: - Helpers
    private func backendFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy hh:mm:ss a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter
    }
    
    @objc private func fromDoneTapped() {
        fromDate = fromPicker.date
        selectFromTimeTextField.text = backendFormatter().string(from: fromPicker.date)
        toPicker.minimumDate = fromPicker.date.addingTimeInterval(60)
        selectFromTimeTextField.resignFirstResponder()
        view.endEditing(true)
    }
    
    @objc private func toDoneTapped() {
        toDate = toPicker.date
        selectToTimeTextField.text = backendFormatter().string(from: toPicker.date)
        selectToTimeTextField.resignFirstResponder()
        view.endEditing(true)
    }
    
    private func resetTimingView() {
        selectFromTimeTextField.text = ""
        selectToTimeTextField.text = ""
        fromDate = nil
        toDate = nil
        selectTimingView.isHidden = true
    }
    
    private func updateEmptyState() {
        if availableTimings.isEmpty {
            availableTimeTableView.backgroundView = emptyAvailableTimingsLabel
        } else {
            availableTimeTableView.backgroundView = nil
        }
    }
}

// MARK: - TableView
extension AvailableTimingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableTimings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AvailableTimingsCell", for: indexPath) as! AvailableTimingsTableViewCell
        let timing = availableTimings[indexPath.row]
        
        cell.configure(fromTime: timing.fromDatetime?.displayDateTime(),
                       toTime: timing.toDatetime?.displayDateTime())
        
        cell.onDeleteTap = { [weak self] in
            self?.showDeleteConfirmation(id: timing.availabilityID, indexPath: indexPath)
        }
        
        return cell
    }
}

// MARK: - String Extensions
extension String {
    func backendToDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy hh:mm:ss a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter.date(from: self)
    }
    
    func displayDateTime() -> String {
        guard let date = backendToDate() else { return self }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, hh:mm a"
        return formatter.string(from: date)
    }
}
