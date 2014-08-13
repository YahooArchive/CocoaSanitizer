//
//  main.cpp
//  ThreadAnalyzer
//
//  Created by Kalpesh Padia on 6/19/14.
//  Copyright (c) 2014 Yahoo! Inc. All rights reserved.
//



#include <iostream>
#include <fstream>
#include <iomanip>
#include <ctime>
#include <unistd.h>

#include "TAErrorCodes.h"
#include "TADataTypes.h"
#include "TAParser.h"
#include "TAUtilities.h"

using namespace std;

/* 
 Defined (and occassionally instantiated) only here. 
 These objects are declared as "extern" in TADataTypes.h.
 Do NOT re-define elsewhere
*/

//map<unsigned long, TACallInfo> callInfoAtTime;
map< string, set<unsigned long> > threadsWorkingOnObjects;
map<unsigned long, TAStack > threadStacks;

set<unsigned long> threads;
set<string> objectAddresses;
set<string> violatingClasses;
set<string> functionWhiteList;
set<string> classnamesWhiteList;
set<string> classnamesSourceList;

//take the arguments supplied at the command line and process it to generate functionWhiteList, classnamesWhiteList
//and open the input file for reading (and output file for writing)
int processArguments(int argc, char** argv, ifstream& ifs, ofstream& ofsAnalysis, ofstream& ofsSummary)
{
    ifstream ifsTemp;
    string line, outputFileName, summaryFileName;
    unsigned long indexSlash, indexDot;
    
    int option;
    
    //while there are still more options to parse
    while ((option = getopt(argc, argv, "c:f:u:")) != -1)
    {
        switch (option) {
            //get the list of classes defined in the application
            case 'u':
                ifsTemp.open(optarg);
                if (ifsTemp.fail())
                {
                    cout<<"Error opening file: "<<optarg<<endl;
                    return ERROR_OPEN;
                }
                    
                cout<<"Reading class names from "<<optarg<<endl;
                while ( getline(ifsTemp, line) )
                {
                    classnamesSourceList.insert(line);
                }
                cout<<"Found "<<classnamesSourceList.size()<<" classes in the application"<<endl;
                    
                ifsTemp.close();
                line = "";
                break;
            
            //get the list of whitelisted classes
            case 'c':
                ifsTemp.open(optarg);
                if (ifsTemp.fail())
                {
                    cout<<"Error opening file: "<<optarg<<endl;
                    return ERROR_OPEN;
                }
                
                cout<<"Reading whitelisted classes from "<<optarg<<endl;
                while ( getline(ifsTemp, line) )
                {
                    classnamesWhiteList.insert(line);
                }
                cout<<"Found "<<classnamesWhiteList.size()<<" whitelisted classes"<<endl;
                
                ifsTemp.close();
                line = "";
                break;
            
            //get the list of the whitelisted functions
            case 'f':
                ifsTemp.open(optarg);
                if (ifsTemp.fail())
                {
                    cout<<"Error opening file: "<<optarg<<endl;
                    return ERROR_OPEN;
                }
                
                cout<<"Reading whitelisted functions from "<<optarg<<endl;
                while ( getline(ifsTemp, line) )
                {
                    functionWhiteList.insert(line);
                }
                cout<<"Found "<<functionWhiteList.size()<<" whitelisted functions"<<endl;
                
                ifsTemp.close();
                line = "";
                break;
            
            //those cases where an option was supplied without argument
            case '?':
                if (optopt == 'c' || optopt == 'f' ||optopt == 'u')
                {
                    cout<<" Option -"<<optopt<<" requires a filename to be supplied"<<endl;
                }
                cout<<"Usage: "<<argv[0]<<" [-f file_function_white_list] [-c file_class_white_list] [-u file_user_defined_classes] trace_file"<<endl;
                return ERROR_ARGS;
            
            default:
                return ERROR_ARGS;
        }
    }
    
    //Check if the name of trace file is supplied
    if (optind == argc)
    {
        cout<<"No trace file supplied"<<endl;
        cout<<"Usage: "<<argv[0]<<" [-f file_function_white_list] [-c file_class_white_list] [-u file_user_defined_classes] trace_file"<<endl;
        return ERROR_ARGS;
    }
    
    //finally get the name of the input file, and open it for reading
    outputFileName = argv[optind];
    summaryFileName = argv[optind];
    
    indexSlash = outputFileName.find_last_of("/")+1;
    indexDot = outputFileName.find_last_of(".");
    
    //construct the output file names
    outputFileName = "output_" + outputFileName.substr(indexSlash, indexDot-indexSlash) + ".html";
    summaryFileName = "summary_" + summaryFileName.substr(indexSlash, indexDot-indexSlash) + ".txt";
    
    //open the input file
    ifs.open(argv[optind]);
    if (ifs.fail())
    {
        cout<<"Error opening file: "<<argv[optind]<<endl;
        return ERROR_OPEN;
    }
    
    ofsAnalysis.open(outputFileName, ofstream::out|ofstream::trunc);
    if (ofsAnalysis.fail())
    {
        cout<<"Error creating output file: "<<outputFileName<<endl;
        return ERROR_OPEN;
    }
    
    ofsSummary.open(summaryFileName, ofstream::out|ofstream::trunc);
    if (ofsSummary.fail())
    {
        cout<<"Error creating output file: "<<summaryFileName<<endl;
        return ERROR_OPEN;
    }
    
    return SUCCESS;
}

unsigned long countLines(istream& is)
{
    unsigned long lineCount = 0;
    string line;
    
    while ( getline(is, line) )
        ++lineCount;
    
    return lineCount;
}

void writeOutputHeader(ostream& os)
{
    os<<"<html><head></head><body><table class='data' border='1' style='font-family: monospace;'>";
    os<<"<tr>"<<"<td width='70'>Object</td>"<<"<td width='70'>Thread</td>"<<"<td width='750'>Info</td>"<<"<td>Stack Trace</td>"<<"</tr>";
    os.flush();
}

void writeOutputFooter(ostream& os)
{
    os<<"</table></body></html>";
    os.flush();
}

void processInputFileAndWriteOutput(ifstream& ifs, ofstream& ofs, unsigned long numLinesTotal)
{
    unsigned long numLinesProcessed = 0;
    string line;
    
    while ( getline(ifs, line) )
    {
        numLinesProcessed++;
        //if the input line is a blank line. This can happen when dtrace introduces blank lines into the output file (usually towards the end)
        //this would cause the sort function to pop the lines to the beginning of the file
        if (line=="")
            continue;
        processLine(line, ofs);
        
        cout<<"Completed: "<<setw(3)<<numLinesProcessed*100/numLinesTotal<<"% ("<<numLinesProcessed<<"/"<<numLinesTotal<<")\r"<<flush;
    }
}

int main(int argc, char **argv) {
    
    unsigned long numLinesTotal;
    int returnCode;
    time_t startTime, endTime;
    ofstream ofsAnalysis, ofsSummary;
    ifstream ifs;
    
    //process the input arguments and return with an error code if any.
    if ((returnCode = processArguments(argc, argv, ifs, ofsAnalysis, ofsSummary)))
        return returnCode;
    
    //count lines in input file
    cout<<"Counting lines in the input file... "<<flush;
    numLinesTotal = countLines(ifs);
    cout<<numLinesTotal<<" lines"<<endl;
    
    //reset and rewind the stream
    ifs.clear();
    ifs.seekg(0, ios::beg);
    
    //write outputheader before the actual processing
    writeOutputHeader(ofsAnalysis);
    
    //Start processing
    cout<<"Reading contents and performing analysis now"<<endl;
    time(&startTime);
    processInputFileAndWriteOutput(ifs, ofsAnalysis, numLinesTotal);
    time(&endTime);
    
    //print stats
    cout<<endl<<"Analysis successful. It took "<<((int)difftime(endTime, startTime)/60)<<" minutes "<<((int)difftime(endTime, startTime)%60)<<" seconds."<<endl;
    cout<<"Total rows in file: "<<rowCount<<endl;
    
    //write output footer
    writeOutputFooter(ofsAnalysis);
    
    //print summary file
    cout<<"Writing summary file now."<<endl;
    printSummary(ofsSummary);
    
    cout<<"All Done."<<endl;
    
    //close all file streams
    ifs.close();
    ofsAnalysis.close();
    ofsSummary.close();
    
    return SUCCESS;
}
