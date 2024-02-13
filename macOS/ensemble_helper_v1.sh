#!/usr/bin/env osascript -l JavaScript

ObjC.bindFunction("sandbox_extension_issue_mach", ["char *", ["char *", "char *", "uint32_t"]])
$.sandbox_extension_issue_mach("com.apple.app-sandbox.mach", "com.apple.axserver", 0)
