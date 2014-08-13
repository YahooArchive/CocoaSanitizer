//
//  TAPolicyChecker.cpp
//  ThreadAnalyzer
//
//  Created by Kalpesh Padia on 6/26/14.
//  Copyright (c) 2014 Yahoo! Inc. All rights reserved.
//

#include <sstream>
#include <functional>
#include <string>

#include "TAPolicyChecker.h"
#include "TADatatypes.h"
#include "TAUtilities.h"

set<TAHashPair> hashPairs;

size_t getHashForStack(TAStack stack)
{
    hash<string> hash;
    string str = "";
    
    while (stack.size())
    {
        TAStackFrame frame = stack.top();
        TACallInfo info = frame.second;
        
        str += to_string(stack.size()) + info.className + info.methodName;
        
        stack.pop();
    }
    
    return hash(str);
}

bool hasSourceClass(TAStack stack)
{
    bool _hasSourceClass = false;
    
    //if classnamesSourceList has some elements
    if (classnamesSourceList.size())
    {
        set<string>::iterator vIt;
        TAStackFrame frame;
        TACallInfo info;
        
        while (stack.size())
        {
            frame = stack.top();
            info = frame.second;
            
            vIt = classnamesSourceList.find(info.className.substr(0,info.className.find_first_of("(")));
            //found in list of class names in source
            if (vIt != classnamesSourceList.end())
                _hasSourceClass = true;
            
            stack.pop();
        }
    }
    else    //the classnames were not supplied, hence by pass this check. 
        _hasSourceClass = true;
    
    return _hasSourceClass;
}

bool isWhiteListed(TACallInfo info)
{
    bool _isWhitelisted = false;
    
    //check against whitelist
    set<string>::iterator vIt = functionWhiteList.find(info.methodName);
    //found in whitelist
    if (vIt != functionWhiteList.end())
        _isWhitelisted = true;
    
    vIt = classnamesWhiteList.find(info.className.substr(0,info.className.find_first_of("(")));
    //found in whitelist
    if (vIt != classnamesWhiteList.end())
        _isWhitelisted = true;
    
    return  _isWhitelisted;
}

void enforcePolicy(unsigned long threadID, ostream& os)
{
    TAStack oStack;
    TACallInfo info;
    TAHashPair hashPair;
    
    bool firstEntry;
    bool oStackHasSourceClass = false;
    bool hashCalculated = false;
    
    string objectAddress;
    string str1="", str2="";
    size_t hash1, hash2;
    
    oStack = threadStacks[threadID];
    objectAddress = oStack.top().first;
    info = oStack.top().second;
    
    firstEntry = true;
    
    //check if the frame on top of stack represents message to/using a whitelisted class/method
    if (isWhiteListed(info))
        return;
    
    for(map<unsigned long, TAStack>::iterator it = threadStacks.begin(); it!= threadStacks.end(); ++it)
    {
        //skip own stack
        if ((*it).first == threadID)
            continue;
        
        TAStack tStack = (*it).second;
        
        //Potential access violation
        if (tStack.top().first == objectAddress)
        {
            TACallInfo info2 = tStack.top().second;
            
            //if whitelisted, continue to next thread
            if (isWhiteListed(info2))
                continue;
            
            /*
             compute the hash for oStack and check if it has source class exactly once per call to this function.
             
             rather than performing this step outside the for loop (to execute it exactly once), we perform this
             step here because for about 75-80% input we will satisfy both "if" conditions above. this means that 
             we would unnecessarily comput hash1 and make a call to hasSourceClass(oStack) if the step is performed
             outside the loop (or earlier than here).
             
             Note: Compiler optimizations in place too.
             -OFast results in a difficult to debug code since the code doesn't stop at breakpoints properly, and
             step-in/step-over results in a difficult to follow execution order -> different from the order in
             which the program is written.
             
            */
            if (!hashCalculated)
            {
                //compute hash for this stack
                hash1 = getHashForStack(oStack);
                //check if this stack has any frame where the class name is one of the classes defined in the source (not a OS class)
                oStackHasSourceClass = hasSourceClass(oStack);
                hashCalculated = true;
            }
            
            //check if the stack(trace) contains a frame where the class name is one of the classes defined in the source (not a OS class)
            if (!oStackHasSourceClass && !hasSourceClass(tStack))
                continue;
            
            //Check for duplication now:
            //first compute hash for the stack
            hash2 = getHashForStack(tStack);
            
            //then find if the hash pair exists
            hashPair = make_pair(hash1, hash2);
            
            if (hashPairs.find(hashPair) == hashPairs.end())
            {
                //this is a new pair
                hashPairs.insert(hashPair);
                
                //Now create a new row for this frame in the output file.
                //If this is the first row for a violation on this object address
                if (firstEntry)
                {
                    os<<"<tr>"<<"<td width='70'>#"<<objectAddress<<"</td><td width='70'>"<<info.tid<<"*"<<"</td><td width='750'>$"<<info.className<<":"<<info.methodName<<" ("<<info.stackDepth<<")"<<"</td><td>";
                    
                    printStackTrace(oStack, os, info.stackDepth);
                    
                    os<<"</td></tr>";
                    firstEntry = false;
                }
                
                //create row for the other frame
                os<<"<tr>"<<"<td width='70'>"<<" "<<"</td><td width='70'>"<<info2.tid<<"</td><td width='750'>$"<<info2.className<<":"<<info2.methodName<<" ("<<info2.stackDepth<<")"<<"</td><td>";
                
                printStackTrace(tStack, os, info2.stackDepth);
                
                os<<"</td></tr>";
                
                //add these class to the set of violating classes
                violatingClasses.insert(info.className);
                violatingClasses.insert(info2.className);
            }
        }
    }
}
