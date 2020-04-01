//
//  ViewController.swift
//  ResourceConsumptionTool
//
//  Created by Suhas Phaniraj on 5/3/18.
//  Copyright © 2018 ResourceConsumptionTool. All rights reserved.
//

import Cocoa


class ViewController: NSViewController {
    
    @IBOutlet weak var processNameTextField: NSTextField!
    @IBOutlet weak var deleteButton: NSButton!
    @IBOutlet weak var processListTableView: NSTableView!
    @IBOutlet weak var tresholdCPU: NSTextField!
    var count = 0
    var cpuThresholdValue = Int()
    @objc var timer = Timer()
    var processNameToAddToArrayAndDictionary = true
    var cpuImage : NSImage!
    let notification = NSUserNotification()
    var selectedRow = -1
    var context = (NSApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    var cpuCompute = Compute()
    var sampleCollect = Sample()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        loadProcess()
        NSUserNotificationCenter.default.delegate = self
        tresholdCPU.integerValue = 20
    }
    
    @objc func timerAction() {
        if count == 3 {
            getResourceUtilizationOfAllProcesses()
            DispatchQueue.main.async {
                self.processListTableView.reloadData()
            }
            count = 0
            selectedRow = -1
        }else{
            count = count + 1
        }
    }
    
    func loadProcess() {
        do{
            cpuCompute.processNamesArray = try context!.fetch(ProcessNames.fetchRequest())
        }
        catch{
            print("Error saving context \(error)")
        }
        
        for processNameToAddToNotifyDictionary in cpuCompute.processNamesArray{
            cpuCompute.dictToStoreResourceConsumptionNotifyValue["\(String(describing: processNameToAddToNotifyDictionary.name!))"]=0
        }
        DispatchQueue.main.async {
            self.processListTableView.reloadData()
        }
    }
    
    func saveProcess(){
        do {
            try context!.save()
        }catch {
            print("Error saving context \(error)")
        }
        DispatchQueue.main.async {
            self.processListTableView.reloadData()
        }
    }
    
    @IBAction func addProcessNameAction(_ sender: NSButton) {
        if processNameTextField.stringValue != "" {
            let process = ProcessNames(context: context!)
            process.name = processNameTextField.stringValue
            for processNameToCheck in cpuCompute.processNamesArray{
                if processNameToCheck.name == processNameTextField.stringValue{
                    processNameToAddToArrayAndDictionary = false
                    break;
                }
            }
            
            if processNameToAddToArrayAndDictionary {
                cpuCompute.processNamesArray.append(process)
                saveProcess()
                processNameTextField.stringValue = ""
                cpuCompute.dictToStoreResourceConsumption["\(String(describing: process.name!))"]=0
                cpuCompute.dictToStoreResourceConsumptionNotifyValue["\(String(describing: process.name!))"] = 0
                loadProcess()
            }
            processNameToAddToArrayAndDictionary = true
        }
    }
    
    
    @IBAction func deleteProcessNameAction(_ sender: NSButton) {
        if selectedRow >= 0 {
            let processToDelete = cpuCompute.processNamesArray[processListTableView.selectedRow]
            let processNameToDelete = processToDelete.name!
            context!.delete(processToDelete)
            saveProcess()
            cpuCompute.processNamesArray.remove(at: processListTableView.selectedRow)
            cpuCompute.dictToStoreResourceConsumption.removeValue(forKey: processNameToDelete)
            cpuCompute.dictToStoreResourceConsumptionNotifyValue.removeValue(forKey: processNameToDelete)
        }
    }
    
    func getResourceUtilizationOfAllProcesses() {
        //cpuThresholdValue = tresholdCPU.integerValue > 0 ? tresholdCPU.integerValue : 20
        cpuCompute.getResourceConsumption(treshold: cpuThresholdValue)
        if cpuCompute.arrayToSaveProcessNameToShowInNotification.count > 0 {
            showNotification(cpuCompute.arrayToSaveProcessNameToShowInNotification as NSArray)
            for processNameToDelete in cpuCompute.arrayToSaveProcessNameToShowInNotification {
                if let index = cpuCompute.arrayToSaveProcessNameToShowInNotification.firstIndex(of: "\(processNameToDelete)") {
                    cpuCompute.arrayToSaveProcessNameToShowInNotification.remove(at: index)
                    cpuCompute.dictToStoreResourceConsumptionNotifyValue["\(processNameToDelete)"] = 0
                }
            }
        }
    }
    
    
    func showNotification(_ arrayToSaveProcessNameToShowInNotification:NSArray) {
        var saveProcessNameToSendNotification = ""
        for name in arrayToSaveProcessNameToShowInNotification{
            saveProcessNameToSendNotification = saveProcessNameToSendNotification + " \(name)"
        }
        notification.title = "\(saveProcessNameToSendNotification)"
        notification.actionButtonTitle = "Open Sample Folder"
        notification.otherButtonTitle = "Cancel"
        notification.hasActionButton = true
        notification.contentImage = cpuImage
        notification.subtitle = "CPU Consumption is high"
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
        sampleCollect.getSampleOfTheProcesses1(arrayToSaveProcessNameToShowInNotification as NSArray)
    }
    
    
    @IBAction func saveOrEditCpuTresholdPercentage(_ sender: NSButton) {
        if sender.title == "Edit" {
            tresholdCPU.isEnabled = true
            cpuThresholdValue = tresholdCPU.integerValue
            sender.title = "Save"
        }else{
            tresholdCPU.isEnabled = false
            cpuThresholdValue = tresholdCPU.integerValue
            sender.title = "Edit"
        }
    }
}

//Mark - TableView Delegates and Datasource methods

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return cpuCompute.processNamesArray.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let processName = cpuCompute.processNamesArray[row]
        if (tableColumn?.identifier)!.rawValue == "ProcessName" {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ProcessName"), owner: self) as? NSTableCellView {
                cell.textField?.stringValue = processName.name!
                return cell
            }
        }else {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ResourceUtilization"), owner: self) as? NSTableCellView {
                cell.textField?.stringValue = cpuCompute.getResourceUtilizationOfEachProcess(processName: processName.name!)
                return cell
            }
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        selectedRow = processListTableView.selectedRow
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
}

//Mark - NSUserNotificationCenter Delegate methods

extension ViewController: NSUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        sampleCollect.openSharedFolder()
    }
}
