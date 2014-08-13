//
//  TAUtilities.h
//  ThreadAnalyzer
//
//  Created by Kalpesh Padia on 6/26/14.
//  Copyright (c) 2014 Yahoo! Inc. All rights reserved.
//

#ifndef ThreadAnalyzer_TAUtilities_h
#define ThreadAnalyzer_TAUtilities_h

#include <iostream>

#include "TADataTypes.h"

using namespace std;

void printStackTrace(TAStack stack, ostream& os, unsigned long frameToHighlight);
void printSummary(ostream& ofs);

#endif
