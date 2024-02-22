//
//  disable_accessibility.c
//  visionOS
//
//  Created by Saagar Jha on 2/22/24.
//

#if DEBUG

#import <objc/runtime.h>

static void UIApplication__accessibilityInit(id self, SEL _cmd) {
}

__attribute__((constructor)) static void init(void) {
	Class class = objc_getClass("UIApplication");
	SEL selector = sel_getUid("_accessibilityInit");
	Method method = class_getInstanceMethod(class, selector);
	class_replaceMethod(class, selector, (IMP)UIApplication__accessibilityInit, method_getTypeEncoding(method));
}

#endif
