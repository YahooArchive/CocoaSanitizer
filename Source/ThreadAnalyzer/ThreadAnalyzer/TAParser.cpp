//
//  TAParser.cpp
//  ThreadAnalyzer
//
//  Created by Kalpesh Padia on 6/26/14.
//  Copyright (c) 2014 Yahoo! Inc. All rights reserved.
//

#include <sstream>

#include "TAParser.h"
#include "TADataTypes.h"
#include "TAPolicyChecker.h"

void pushDummyFramesOntoStack(TAStack& stack, unsigned long numFramesToPush)
{
    TACallInfo dummy;
    dummy.tid = 0;
    dummy.stackDepth = 0;
    dummy.objectAddress = "";
    dummy.methodName = "";
    dummy.className = "";
    
    for (unsigned long i=0; i<numFramesToPush; i++)
        stack.push(make_pair("",dummy));
}

void recordObjectAddressAccessByThread(string objectAddress, unsigned long threadId)
{
    //find if we have a record this object being accessed by any threads
    if (threadsWorkingOnObjects.find(objectAddress) == threadsWorkingOnObjects.end())
    {
        //if there is no record for this object, create an empty record
        set<unsigned long> temp;
        threadsWorkingOnObjects[objectAddress] = temp;
    }
    //add this thread to the set of threads accessing this object
    threadsWorkingOnObjects[objectAddress].insert(threadId);
}

void pushCallInfoToStack(TACallInfo& callInfo)
{
    //if this thread is encountered for the first time
    if (threadStacks.find(callInfo.tid) == threadStacks.end())
    {
        //create a new stack for this thread
        TAStack newStack;
        
        //push callInfo.stackDepth-1 dummy frames
        pushDummyFramesOntoStack(newStack, callInfo.stackDepth-1);
        
        //push the object we want at appropriate depth
        newStack.push(make_pair(callInfo.objectAddress,callInfo));
        
        //insert this stack in our map
        threadStacks.insert(make_pair(callInfo.tid, newStack));
    }
    else
    {
        //find the current stack depth
        TAStack tStack = threadStacks[callInfo.tid];
        unsigned long st_size = tStack.size();
        
        //and push or pop the difference
        //if same depth, pop one
        if (st_size == callInfo.stackDepth)
        {
            tStack.pop();
        }
        //if current size is less than the depth of the frame
        else if (st_size < callInfo.stackDepth)
        {
            //push diff-1 dummy frames
            pushDummyFramesOntoStack(tStack, (callInfo.stackDepth-st_size)-1);
        }
        //if current size is more than the depth of the frame
        else
        {
            //pop diff+1 frames
            for (unsigned long i=st_size; i>callInfo.stackDepth-1; i--)
                tStack.pop();
        }
        
        //now push the current object
        tStack.push(make_pair(callInfo.objectAddress,callInfo));
        threadStacks[callInfo.tid] = tStack;
    }

}

void processLine(string& line, ostream& os)
{
    TACallInfo callInfo;
    istringstream iss(line);
    
    //read the details from the stream
    iss>>callInfo.timestamp>>callInfo.tid>>callInfo.stackDepth>>callInfo.objectAddress>>callInfo.className>>callInfo.methodName;
    
    //insert this thread into set of all threads
    threads.insert(callInfo.tid);
    
    //insert this object address into set of all object addresses
    objectAddresses.insert(callInfo.objectAddress);
    
    //save this callInfo onto apporpriateStack
    pushCallInfoToStack(callInfo);
    
    //check for concurrent usage
    enforcePolicy(callInfo.tid, os);
    
    //mark that thread tid accessed this objectaddress
    recordObjectAddressAccessByThread(callInfo.objectAddress, callInfo.tid);
}