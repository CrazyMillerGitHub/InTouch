//
//  ConversationsListViewController.swift
//  InTouchApp
//
//  Created by Михаил Борисов on 21/02/2019.
//  Copyright © 2019 Mikhail Borisov. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import CoreData
class ConversationsListViewController: UIViewController, dataDelegate {
    func reloadData(status: Bool) {
        if status == true {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    /// Present ProfileViewController
    ///
    /// - Parameter sender: sender
    @IBAction func profileAction(_ sender: Any) {
        let rootProfileView = sendActionWithIdentifier(withIdentifier: "rootProfileSTR")
        self.present(rootProfileView, animated: true, completion: nil)
    }
    
    /// Выбор темы в настройках
    ///
    /// - Parameter sender: sender
    @IBAction func settingAction(_ sender: Any) {
        let rootProfileView = sendActionWithIdentifier(withIdentifier: "rootThemeSTD")
        guard let segueViewController = rootProfileView.topViewController as? ThemesViewController else { fatalError() }
        segueViewController.model = Themes()
        segueViewController.delegate = self
        self.present(rootProfileView, animated: true, completion: nil)
    }
    
    func sendActionWithIdentifier(withIdentifier id: String) -> UINavigationController {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let rootViewController = storyBoard.instantiateViewController(withIdentifier: id) as? UINavigationController else { fatalError()
        }
        return rootViewController
    }
    
    /// NSFetchResultController
    lazy var fetchedResultsController: NSFetchedResultsController<User> = {
        let request: NSFetchRequest<User> = User.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        let frc =  NSFetchedResultsController(fetchRequest: request, managedObjectContext: StorageManager.Instance.coreDataStack.mainContext, sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()
    
    @IBOutlet private var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        self.tableView.dataSource = self
        self.tableView.delegate = self
        CommunicatorManager.instance.delegate = self
        CommunicatorManager.instance.communicator.advertiser.startAdvertisingPeer()
        CommunicatorManager.instance.communicator.browser.startBrowsingForPeers()
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {}
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
}

// MARK: - Закоментить extension, если ThemesViewController - swift file
extension ConversationsListViewController: ThemesViewControllerDelegate {
    func themesViewController(_ controller: ThemesViewController, didSelectTheme selectedTheme: UIColor) {
        logThemeChanging(selectedTheme: selectedTheme)
    }
}


// MARK: - NSFetchedResultsControllerDelegate
extension ConversationsListViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        //swiftlint:disable force_unwrapping
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        }
        //swiftlint:enable force_unwrapping
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ConversationsListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? TableViewCell else { fatalError() }
        let user = self.fetchedResultsController.object(at: indexPath)
        if let image = user.image {
            cell.profileImage.image = UIImage(data: image)
            cell.profileImage.layer.cornerRadius = 22.5
        }
        let message = user.lastMessage ?? ""
        let online = user.isOnline
        guard let userID = user.userID else { fatalError("No found UserID. Are you Okay?") }
        let date = Conversation.requestLastMessageWithCurrectId(in: StorageManager.Instance.coreDataStack.mainContext, conversationID: userID)?.date
        let name = user.name ?? ""
        cell.configureCell(name: name, message: message, date: date, online: online, hasUnreadmessage: true)
        // swiftlint:enable force_cast
        return cell
    }
    
    private func convertToDate(from string: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = dateFormatter.date(from: string) else {
            return Date()
        }
        return date
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = self.fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        print(sectionInfo.numberOfObjects)
        return sectionInfo.numberOfObjects
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let managedObject = fetchedResultsController.object(at: indexPath)
            StorageManager.Instance.coreDataStack.mainContext.delete(managedObject)
            do {  StorageManager.Instance.coreDataStack.performSave()
                let request2: NSFetchRequest<User> = User.fetchRequest()
                do {
                    let result2 = try StorageManager.Instance.coreDataStack.mainContext.fetch(request2)
                    print(result2.count)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let messageViewController = storyBoard.instantiateViewController(withIdentifier: "messageStb") as? ConversationViewController else {
            fatalError()
        }
        guard let row = tableView.indexPathForSelectedRow?.row else { return }
        messageViewController.userId = self.fetchedResultsController.fetchedObjects?[row].userID
        messageViewController.title = self.fetchedResultsController.fetchedObjects?[row].name
        self.navigationController?.pushViewController(messageViewController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func logThemeChanging(selectedTheme: UIColor) {
        switch selectedTheme {
        case .white:
            if let selectedTheme = Theme(rawValue: 0) {
                selectedTheme.apply()
            }
        case .black:
            if let selectedTheme = Theme(rawValue: 1) {
                selectedTheme.apply()
            }
        default:
            if let selectedTheme = Theme(rawValue: 2) {
                selectedTheme.apply()
            }
        }
    }
}

protocol ConversationCellonfiguration: class {
    var name: String? {get set}
    var message: String? {get set}
    var date: Date? {get set}
    var online: Bool {get set}
    var hasUnreadMessage: Bool {get set}
}
