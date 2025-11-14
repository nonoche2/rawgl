#import <Foundation/Foundation.h>
#include "MacHelper.h"
#include <string>
#include <cstdio>  // for printf

// Replace warning() with printf
static void mac_warning(const char* msg) {
    printf("MacHelper: %s\n", msg);
}

std::string getResourcesFolder() {
    @autoreleasepool {
        NSBundle *bundle = [NSBundle mainBundle];
        if (!bundle) {
            mac_warning("[NSBundle mainBundle] returned nil");
            return "";
        }
        NSString *path = [bundle resourcePath];
        if (!path) {
            mac_warning("[mainBundle resourcePath] returned nil");
            return "";
        }
        return std::string([path UTF8String]);
    }
}

std::string getSystemLanguage() {
    @autoreleasepool {
        NSArray *langs = [NSLocale preferredLanguages];
        if ([langs count] == 0) return "us";

        NSString *lang = [langs objectAtIndex:0];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:lang];
        NSString *code = [locale objectForKey:NSLocaleLanguageCode];

        if ([code isEqualToString:@"fr"]) return "fr";
        if ([code isEqualToString:@"en"]) return "us";
        if ([code isEqualToString:@"de"]) return "de";
        if ([code isEqualToString:@"es"]) return "es";
        if ([code isEqualToString:@"it"]) return "it";

        return "us";
    }
}
