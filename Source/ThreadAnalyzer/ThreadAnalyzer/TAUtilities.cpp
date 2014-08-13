//
//  TAUtilities.cpp
//  ThreadAnalyzer
//
//  Created by Kalpesh Padia on 6/26/14.
//  Copyright (c) 2014 Yahoo! Inc. All rights reserved.
//
#include <fstream>
#include <iomanip>

#include "TAUtilities.h"

unsigned long rowCount = 0;

void printStackTrace(TAStack stack, ostream& os, unsigned long frameToHighlight)
{
    os<<"<table>";
    while (stack.size())
    {
        TAStackFrame frame = stack.top();
        TACallInfo info = frame.second;
        
        os<<"<tr>";
        
        if (stack.size() == frameToHighlight)
            os<<"<td><b>"<<stack.size()<<":</b></td><td><b>"<<" ("<<info.objectAddress<<")"<<info.className<<":"<<info.methodName<<"</b></td>";
        else
            os<<"<td>"<<stack.size()<<":</td><td>"<<" ("<<info.objectAddress<<")"<<info.className<<":"<<info.methodName<<"</td>";
        
        
        os<<"</tr>";
        
        stack.pop();
    }
    os<<"</table>";
    rowCount++;
}

void printSummary(ostream& os)
{

    for (int i=0;i<72;i++)
        os<<"=";
    os<<endl;
    os<<objectAddresses.size()<<" objects accessed by "<<threads.size()<<" threads"<<endl;
    for (int i=0;i<72;i++)
        os<<"=";
    os<<endl;
    os<<endl<<endl;
    
    for (int i=0;i<72;i++)
        os<<"=";
    os<<endl;
    os<<"List of violating classes follows: "<<endl;
    for (int i=0;i<72;i++)
        os<<"=";
    os<<endl;
    
    for (set<string>::iterator it=violatingClasses.begin(); it!= violatingClasses.end(); ++it)
        os<<*it<<endl;
    for (int i=0;i<72;i++)
        os<<"=";
    os<<endl;
    os<<endl<<endl;
    
    /*
    for (int i=0;i<72;i++)
        os<<"=";
    os<<endl;
    os<<"List of object access by thread follows: "<<endl;
    for (int i=0;i<72;i++)
        os<<"=";
    os<<endl;
    
    os<<setw(8)<<"Object"<<" "<<setw(8)<<"Thread(s)"<<endl;
    for (int i=0;i<72;i++)
        os<<"-";
    os<<endl;
    
    for (map< string, set<unsigned long> >::iterator it = threadsWorkingOnobjectAddresses.begin(); it != threadsWorkingOnobjectAddresses.end(); ++it)
    {
        set<unsigned long> temp = (*it).second;
        os<<setw(8)<<(*it).first<<" ";
        
        for (set<unsigned long>::iterator itt = temp.begin(); itt != temp.end(); ++itt)
            os<<setw(8)<<*itt<<" ";
        
        os<<endl;
    }
    for (int i=0;i<72;i++)
        os<<"=";
    os<<endl;
    */
}