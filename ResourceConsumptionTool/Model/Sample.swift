//
//  Sample.swift
//  ResourceConsumptionTool
//
//  Created by Suhas on 29/03/20.
//  Copyright © 2020 ResourceConsumptionTool. All rights reserved.
//

import Foundation

struct Sample {
    var getResourceOfProcess = Compute()
    
    
    func getSampleOfTheProcesses1(_ arrayContainingNamesToTakeSample:NSArray)  {
        for processNameInArray in arrayContainingNamesToTakeSample{
            let task1 = Process()
            let pipe1 = Pipe()
            task1.launchPath = "/usr/bin/pgrep"
            task1.arguments = ["-x",processNameInArray as! String]
            task1.standardOutput = pipe1
            task1.standardError = pipe1
            do {
                try task1.run()
            }catch {
                print("Error: \(error)")
            }
            let handle1 = pipe1.fileHandleForReading
            let data1 = handle1.readDataToEndOfFile()
            let processIDObtainedFromCode = String (data: data1, encoding: String.Encoding.utf8)
            
            

            // Task 2 to get the sample of the processes
            let task2 = Process()
            let pipe2 = Pipe()
            task2.launchPath = "/usr/bin/sample"
            task2.arguments = [processIDObtainedFromCode!.replacingOccurrences(of: "\n", with: ""), "4" ,"-file", "/Users/Shared/Sample_\(processNameInArray as! String).txt"]
            task2.standardInput = task1.standardOutput
            task2.standardOutput = pipe2
            do {
                try task2.run()
            }catch {
                print("Error: \(error)")
            }
            let handle2 = pipe2.fileHandleForReading
            let data2 = handle2.readDataToEndOfFile()
            let printing = String (data: data2, encoding: String.Encoding.utf8)
            print(printing!)
        }
    }
    
    func openSharedFolder() {
        let task1 = Process()
        let pipe1 = Pipe()
        task1.launchPath = "/usr/bin/open"
        task1.arguments = ["/Users/Shared"]
        task1.standardOutput = pipe1
        task1.standardError = pipe1
        do {
            try task1.run()
        }catch {
            print("Error: \(error)")
        }
        let handle1 = pipe1.fileHandleForReading
        let data1 = handle1.readDataToEndOfFile()
        let openTheSampledLocation = String (data: data1, encoding: String.Encoding.utf8)
        print(openTheSampledLocation!)
    }
}
