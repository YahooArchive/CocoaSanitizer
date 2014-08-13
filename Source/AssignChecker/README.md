#AssignChecker
## Overview
This tool is designed to root out a major cause of 'unrecognized selector' style crashes: an object which was deallocated was left visible to another object via an 'assign' style property.  For example, a UIViewController which deallocates before a UITableView, where the view controller acts as the table view's data source.  (In some situations the table view may outlive the view controller -- eg., it's being retained while an animation runs).

The assign checker monitors the setting of any 'assign' id style property, and then monitors the lifetime of the object being set.  When the object being set is deallocted, it verifies that the property has also been cleared.  If the property has not yet been nil'd out, an error is reported.

This kind of error can be fixed in the following ways:

1. Make the property 'weak' instead of assign.
2. If number 1 is not possible (maybe the class is not owned by you), then the property needs to be cleared in dealloc.  For example, in the UIViewController/TableView example, the UIViewController's dealloc should clear out the table view's data source.

## Requirements
* Currently only the iOS Simulator is supported
* Only supports having a single command active at any time

## Installation
1. Download the 'CocoaSanitizer/Release/AssignChecker' folder (downloading the project source is totally optional)
2. Rename the folder to 'cocoasanitizer'
3. Copy the 'cocoasanitizer' folder to /usr/local/lib
4. Add the following line to your _~/.lldbinit_ file. If it doesn't exist, create it.

```bash
command script import /usr/local/lib/cocoasanitizer/lldbassignchecker.py
```

The commands will be available the next time `Xcode` starts.

## Usage
### Activating 
* Build for the simulator, in 32-bit mode
* Put a breakpoint in your application's did finish launch method.
* When you stop in the debugger, type one of the commands to activate the various tools:

|Command                           |Description|
|----------------------------------|-----------|
|cocoasanitizer_assignchecker      |starts the assign checker tool|

### Output
The tool will generate errors both to the console, and to a text file generated in your application sandbox 'tmp' folder.

For example:

```bash
AssignChecker [2]: Assign error: 0xd22f000 (UITableView) dataSource now points to a deallocated object 0x8e6a160 (BMPSampleTableViewDataSource)
 via: 
(
	0   AssignCheckerDemoiOSApp            0x00004a81 __55-[BMPAssignChecker p_monitorSetterOfProperty:ofClass:]_block_invoke_2 + 1265
	1   libobjc.A.dylib                     0x0044f692 _ZN11objc_object17sidetable_releaseEb + 268
	2   libobjc.A.dylib                     0x0044ee81 objc_release + 49
	3   libobjc.A.dylib                     0x0044ee3e objc_storeStrong + 39
	4   AssignCheckerDemoiOSApp            0x00002949 -[BMPViewController setDataSource:] + 57
	5   AssignCheckerDemoiOSApp            0x0000274e -[BMPViewController didTapTestButton:] + 94
	6   libobjc.A.dylib                     0x00450880 -[NSObject performSelector:withObject:withObject:] + 77
	7   UIKit                               0x006513b9 -[UIApplication sendAction:to:from:forEvent:] + 108
	8   UIKit                               0x00651345 -[UIApplication sendAction:toTarget:fromSender:forEvent:] + 61
	9   UIKit                               0x00752bd1 -[UIControl sendAction:to:forEvent:] + 66
	10  UIKit                               0x00752fc6 -[UIControl _sendActionsForEvents:withEvent:] + 577
	11  UIKit                               0x00752243 -[UIControl touchesEnded:withEvent:] + 641
	12  UIKit                               0x00690ddd -[UIWindow _sendTouchesForEvent:] + 852
	13  UIKit                               0x006919d1 -[UIWindow sendEvent:] + 1117
	14  UIKit                               0x006635f2 -[UIApplication sendEvent:] + 242
	15  UIKit                               0x0064d353 _UIApplicationHandleEventQueue + 11455
	16  CoreFoundation                      0x0157477f __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__ + 15
	17  CoreFoundation                      0x0157410b __CFRunLoopDoSources0 + 235
	18  CoreFoundation                      0x015911ae __CFRunLoopRun + 910
	19  CoreFoundation                      0x015909d3 CFRunLoopRunSpecific + 467
	20  CoreFoundation                      0x015907eb CFRunLoopRunInMode + 123
	21  GraphicsServices                    0x029195ee GSEventRunModal + 192
	22  GraphicsServices                    0x0291942b GSEventRun + 104
	23  UIKit                               0x0064ff9b UIApplicationMain + 1225
	24  AssignCheckerDemoiOSApp            0x00002bad main + 141
	25  libdyld.dylib                       0x025b2701 start + 1
) 

 original set: (
	0   AssignCheckerDemoiOSApp            0x000042c5 __55-[BMPAssignChecker p_monitorSetterOfProperty:ofClass:]_block_invoke + 2117
	1   AssignCheckerDemoiOSApp            0x00002664 -[BMPViewController viewDidLoad] + 212
	2   UIKit                               0x0076e33d -[UIViewController loadViewIfRequired] + 696
	3   UIKit                               0x0076e5d9 -[UIViewController view] + 35
	4   UIKit                               0x0068e267 -[UIWindow addRootViewControllerViewIfPossible] + 66
	5   UIKit                               0x0068e5ef -[UIWindow _setHidden:forced:] + 312
	6   UIKit                               0x0068e86b -[UIWindow _orderFrontWithoutMakingKey] + 49
	7   UIKit                               0x006993c8 -[UIWindow makeKeyAndVisible] + 65
	8   UIKit                               0x00649bc0 -[UIApplication _callInitializationDelegatesForURL:payload:suspended:] + 2097
	9   UIKit                               0x0064e667 -[UIApplication _runWithURL:payload:launchOrientation:statusBarStyle:statusBarHidden:] + 824
	10  UIKit                               0x00662f92 -[UIApplication handleEvent:withNewEvent:] + 3517
	11  UIKit                               0x00663555 -[UIApplication sendEvent:] + 85
	12  UIKit                               0x00650250 _UIApplicationHandleEvent + 683
	13  GraphicsServices                    0x0291af02 _PurpleEventCallback + 776
	14  GraphicsServices                    0x0291aa0d PurpleEventCallback + 46
	15  CoreFoundation                      0x01566ca5 __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__ + 53
	16  CoreFoundation                      0x015669db __CFRunLoopDoSource1 + 523
	17  CoreFoundation                      0x0159168c __CFRunLoopRun + 2156
	18  CoreFoundation                      0x015909d3 CFRunLoopRunSpecific + 467
	19  CoreFoundation                      0x015907eb CFRunLoopRunInMode + 123
	20  UIKit                               0x0064dd9c -[UIApplication _run] + 840
	21  UIKit                               0x0064ff9b UIApplicationMain + 1225
	22  AssignCheckerDemoiOSApp            0x00002bad main + 141
	23  libdyld.dylib                       0x025b2701 start + 1
```
 
* The error will tell you which class contained the setter, what the type of the value was, the instance of both objects, and the backtraces of the dealloc, and of the original set.
* To make a fix, you'd usually nil out a delegate/etc. from within the dealloc of the class mentioned in the second backtrace.  In the above example, BMPViewController's dealloc needs to clear out the table view dataSource.

### Other notes

* While the tool does not report 'false positives' (every error reported represents a bit of code which is not cleaning up a resource properly), it does not neccesarily mean that the bug will cause your app to crash, it just means your app could crash if the object with the setter outlives the other object.
* The tool is designed only to look at set calls coming from code within your application's binary (it does not monitor communication between 2 classes in the OS).
* This tool is not designed for CPU or memory performance, don't have it enabled while checking for performance or leaks in your application.

## Building from source
Before you build from source, you need to make the following changes to enable iOS dynamic library compilation support in Xcode. Without the following changes, Xcode will complain:
```
target specifies product type 'com.apple.product-type.library.dynamic', but there's no such product type for the 'iphonesimulator' platform
```
To enable iOS dynamic library compilation support, make the following changes:
* Open the Mac OS product specification file:

```
/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Specifications/MacOSX Product Types.xcspec
```
and copy the section ```com.apple.product-type.library.dynamic``` to the iOS product specification file:
```
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Xcode/Specifications/iPhone Simulator ProductTypes.xcspec
```

* Open the Mac OS package specification file:

```
/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Specifications/MacOSX Package Types.xcspec
```
and copy the section ```com.apple.package-type.mach-o-dylib``` to the iOS package specification file:
```
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Xcode/Specifications/iPhone Simulator PackageTypes.xcspec
```

* Restart Xcode.
* Open the workspace and build for simulator. The output will be copied to CocoaSanitizer/Release/AssignChecker folder

## Contact

Brian Tunning (iOS Engineer)<br />
