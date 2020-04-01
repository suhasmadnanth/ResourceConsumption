//
//  Compute.swift
//  ResourceConsumptionTool
//
//  Created by Suhas on 28/03/20.
//  Copyright © 2020 ResourceConsumptionTool. All rights reserved.
//

import Foundation
struct Compute {
    
    var processNamesArray : [ProcessNames] = []
    var consumption = 0
    var dictToStoreResourceConsumption = [String:Int]()
    var dictToStoreResourceConsumptionNotifyValue = [String:Int]()
    var arrayToSaveProcessNameToShowInNotification = [String]()
    
    mutating func getResourceConsumption(treshold: Int){
       for process in processNamesArray {
       consumption = (getResourceUtilizationOfEachProcess(processName: process.name!) as NSString).integerValue
            print("The dictToStoreResourceConsumptionNotifyValue is \(dictToStoreResourceConsumptionNotifyValue)")
    
            if consumption > treshold {
                dictToStoreResourceConsumptionNotifyValue["\(String(describing: process.name!))"] = dictToStoreResourceConsumptionNotifyValue["\(process.name!)"]! + 1
                
            }else{
                dictToStoreResourceConsumptionNotifyValue["\(String(describing: process.name!))"] = 0
            }
        dictToStoreResourceConsumption["\(process.name!)"] = consumption
        print("dictToStoreResourceConsumption is \(dictToStoreResourceConsumption)")
        }
        for (name, cpuConsumptionValue) in dictToStoreResourceConsumptionNotifyValue {
            if cpuConsumptionValue > 3 {
                arrayToSaveProcessNameToShowInNotification.append(name)
                print("arrayToSaveProcessNameToShowInNotification: \(arrayToSaveProcessNameToShowInNotification)")
            }
        }

    }
    
    func getResourceUtilizationOfEachProcess(processName: String) -> String {
        let processNameToProcessIDTask = Process()
         let processNameToProcessIDPipe = Pipe()
         processNameToProcessIDTask.launchPath = "/usr/bin/pgrep"
         processNameToProcessIDTask.arguments = ["-x",processName]
        
         processNameToProcessIDTask.standardOutput = processNameToProcessIDPipe
         processNameToProcessIDTask.standardError = processNameToProcessIDPipe
         do {
             try processNameToProcessIDTask.run()
         }catch {
             print("Error: \(error)")
         }
         let processNameToProcessIDData = processNameToProcessIDPipe.fileHandleForReading.readDataToEndOfFile()
         let processIDObtainedFromCode = String (data: processNameToProcessIDData, encoding: String.Encoding.utf8)
         
         // Task Two
         let getCPUConsumptionFromProcessIDTask = Process()
         let getCPUConsumptionFromProcessIDPipe = Pipe()
         getCPUConsumptionFromProcessIDTask.launchPath = "/bin/ps"
         getCPUConsumptionFromProcessIDTask.arguments = ["-p",processIDObtainedFromCode!.replacingOccurrences(of: "\n", with: ""),"-o","%cpu"]
         getCPUConsumptionFromProcessIDTask.standardInput = processNameToProcessIDTask.standardOutput
         getCPUConsumptionFromProcessIDTask.standardOutput = getCPUConsumptionFromProcessIDPipe
         do {
             try getCPUConsumptionFromProcessIDTask.run()
             }catch {
             print("Error: \(error)")
         }
         let getCPUConsumptionFromProcessIDData = getCPUConsumptionFromProcessIDPipe.fileHandleForReading.readDataToEndOfFile()
         let output = String (data: getCPUConsumptionFromProcessIDData, encoding: String.Encoding.utf8)
         let cpuConsumptionOFProcessFromProcessID = output?.replacingOccurrences(of: "%CPU\n", with: "")
         return (cpuConsumptionOFProcessFromProcessID!)
    }
}
