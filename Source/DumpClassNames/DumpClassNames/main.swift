//
//  main.swift
//  DumpClassNames
//
//  Created by Brian Tunning on 7/4/14.
//  Copyright (c) 2014 Yahoo. All rights reserved.
//

import Foundation

func executableFileNameFromAppFilePath(appFilePath:String) -> String?
{
    let components = appFilePath.componentsSeparatedByString("/")
    
    if (components.count == 0) {
        return nil
    }
    
    let lastComponent = components[components.count-1]
    
    // trim the trailing extension
    let charCount = countElements(lastComponent)
    
    var index: String.Index = lastComponent.startIndex
    advance(index, charCount - 4)
    
    let withoutExtension = lastComponent.substringToIndex(index)
    
    return withoutExtension
}

func objcOutputFromExecutableFile(filePath:String) -> String
{
    // define a completion block to accumulate the data
    let data = NSMutableData()
    let completionBlock: (NSFileHandle!) -> Void = {file in
        
        let chunk = file.availableData
        data.appendData(chunk)
    }
    
    let pipe = NSPipe()
    pipe.fileHandleForReading.readabilityHandler = completionBlock
    
    // define the task
    let task = NSTask()
    task.launchPath = "/usr/bin/otool"
    task.arguments = ["-ov", filePath]
    task.standardOutput = pipe
    task.standardError = NSFileHandle.fileHandleWithStandardError()
    
    task.launch()
    task.waitUntilExit()
    
    return NSString(data: data, encoding: NSUTF8StringEncoding)
}

func classNamesFromOToolOutput(otoolOutput:String) -> NSSet!
{
    let inputAsNSString:NSString = otoolOutput
    
    // make a range across the string
    let all = NSMakeRange(0, otoolOutput.utf16Count)
    
    // create a pattern
    //                  0         1    2       3        4     5    6
    let pattern = "(Meta Class)(\n.*){0,10}(\n[\t ]+)(name )(.* )(.*)"
    let classNameRangeIndex = 6
    var parseRegexError : NSError?
    let regEx:NSRegularExpression = NSRegularExpression(pattern: pattern, options: nil, error: &parseRegexError)
    
    // fail if we were unable to setup the regex
    if ((parseRegexError) != nil) {
        println(object: STDERR_FILENO, "unable to parse regex: \(parseRegexError!.localizedFailureReason)")
        return nil
    }
    
    // set up an array for sorting
    let classNames:NSMutableSet = NSMutableSet()
    
    regEx.enumerateMatchesInString(otoolOutput, options:nil, range:all, usingBlock:{
        (result:NSTextCheckingResult!, flags:NSMatchingFlags, stop:UnsafeMutablePointer<ObjCBool>) in
        
        // TODO: improve this once there's a clear way to get a substring from a Swift String instance
        let classNameRange = result.rangeAtIndex(classNameRangeIndex)
        let className = inputAsNSString.substringWithRange(classNameRange)
        
        classNames.addObject(className)
        })
    
    return classNames
}

func main()
{
    // first param is the executable path (implicit), 2nd param is the input file path
    let minArgumentCount = 2
    let inputFilePathArgumentIndex = 1
    
    // fail if argument count is not correct
    if (Process.arguments.count < minArgumentCount) {
        println(object: STDERR_FILENO, "missing required parameter.")
        return
    }
    
    // process the input
    let filePath:String = Process.arguments[inputFilePathArgumentIndex]
    var executableFilePath:String?

    if let executableFileName = executableFileNameFromAppFilePath(filePath) {
        executableFilePath = filePath + "/" + executableFileName
    }
    
    // fail if we can't build a path to the exe
    if (executableFilePath == nil) {
        println(object: STDERR_FILENO, "cannot build path to executable.")
        return
    }
    
    // generate objc debug info
    let otoolOutput:String = objcOutputFromExecutableFile(executableFilePath!)
    let classNames = classNamesFromOToolOutput(otoolOutput)

    let comparator: (AnyObject!, AnyObject!) -> NSComparisonResult = {obj1, obj2 in
        
        let first = obj1 as NSString
        let second = obj2 as NSString
        
        return first.compare(second)
    }
    
    let sortedClassNames:NSArray = (classNames.allObjects as NSArray).sortedArrayUsingComparator(comparator)
    
    // output to stream
    for className : AnyObject in sortedClassNames {
        println(className)
    }
}

main()
