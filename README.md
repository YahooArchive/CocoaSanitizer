#CocoaSanitizer
A suite of dynamic analysis tools to find bugs at design time.  The tools leverage the Objective-C runtime, to look for common anti-patterns which can lead to crashes.
Like any dynamic analysis tool, your target program must be exercised with sufficient input to produce interesting behavior.

##Tools
Here is a brief summary of each tool. For detailed information about what the tool does, and how to use it please check readme for the concerned tool.
###AssignChecker
The first tool in the suite is the AssignChecker. This tool is designed to root out a major cause of 'unrecognized selector' style crashes: an object which was deallocated was left visible to another object via an 'assign' style property. The assign checker monitors the setting of any 'assign' id style property, and then monitors the lifetime of the object being set. When the object being set is deallocted, it verifies that the property has also been cleared. If the property has not yet been nil'd out, an error is reported.

The tool is packaged as an iOS .dylib, appropriate for use with the iOS simulator.  This packaging allows the tool to be used in any iOS project, without needing to change your source code or build settings.

###ThreadAnalyzer
This is the second tool in the suite. It is very common to encounter situations where a non-thread safe object is accessed simulataneously by two or more threads. Crashes or unexpected behavior ensuing such access is often difficult to detect and even more difficult to prove.

This tool is designed to highlight such simultaneous access and identify potential causes of thread safety violation in your application. As input the tool expects output from dtrace - a kernel level tracing utility which can be used to capture every message sent (method call/access) to an object during the lifetime of application.
When run without any other input, the tool highlights all concurrent object access throughout the lifetime of the application. Custom whitelists - files containing lists of known thread safe classes and functions - can also be supplied to the tool in order to exclude these from the analysis.
Since dtrace can be attached to any running application, you can use this tool to identify concurrent access in any application, and not just iOS applications.


###DumpClassNames
This tool performs a quick scan of a Mac OS X/iOS application and outputs a list of user defined classes in the application. 

This tool can be used by itself for investigating the different classes implemented by the application, or its output can be supplied to ThreadAnalyzer to restrict the analysis to user defined classes.


## Requirements
* Currently only Mac OS X running Xcode 5 or above is supported

## Installation

1. Download the 'Release' folder (downloading the project source is totally optional)
2. Each tool is provided within it's own folder under Release. Please check tool specific readme for more information on how to execute the tool

## Building from source
While building from source is completely optional, you can do so by downloading the provided source. Note that the tools have been developed for Mac OS X and iOS Simulator, and have not been compiled, run or tested on any other platform. You should download all source code, and open ```CocoaSanitizer.workspace``` in Xcode. You can then choose individual schemes to build and run individual tools. Some tools require additional configuration before they can be compiled. More details can be found in the project specific readme.


## Contact

[Brian Tunning](http://backyard.yahoo.com/tools/g/employee/profile?user_id=btunning) (iOS Enigneer)<br />
