#DumpClassNames
##Overview
This tool performs a quick scan of a Mac OS X/iOS application and outputs a list of user defined classes in the application.

This tool can be used by itself for investigating the different classes implemented by the application, or its output can be supplied to ThreadAnalyzer to restrict the analysis to user defined classes.

##Requirements
* You must be running Mac OS X 10.9 or later with Xcode 6 or later (Swift application \m/)

##Installation
Download the 'CocoaSanitizer/Release/DumpClassNames' folder (downloading the project source is totally optional)

##Usage
Open a terminal window and issue a command similar to 

```
$./DumpClassNames "path to application.app"
```

###Output
By default the tool outputs the names of all user defined classes in the application to the console. You may redirect the output to a file if required. 

##Building from Source
* Download all files under 'CocoaSanitizer/Source/DumpClassNames' to similar path structure on your machine
* Compile in Xcode 6 or later
* The output binary will be automatically copied to 'CocoaSanitizer/Release/DumpClassNames'

##Contact
Brian Tunning (iOS Engineer)<br />
