import lldb
import commands

def __lldb_init_module(debugger, internal_dict):
    debugger.HandleCommand('command script add -f lldbassignchecker.cocoasanitizer_activate_assignchecker_impl cocoasanitizer_assignchecker')

def cocoasanitizer_activate_assignchecker_impl(debugger, command, result, internal_dict):
	debugger.HandleCommand('expr (void*) dlopen("/usr/local/lib/cocoasanitizer/AssignChecker.dylib", 0x2)')
	debugger.HandleCommand('expr (void) [BMPAssignChecker start]')
