#import <Foundation/Foundation.h>
#include "MacHelper.h"
#include <string>
#include <cstdio>  // for printf

// Replace warning() with printf
static void mac_warning(const char* msg) {
    printf("MacHelper: %s\n", msg);
}

std::string getApplicationSupportPath() {
    @autoreleasepool {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        if ([paths count] == 0) {
            mac_warning("NSSearchPathForDirectoriesInDomains for NSApplicationSupportDirectory returned no paths");
            return "";
        }

        NSString *appSupportDir = [paths objectAtIndex:0];
        NSString *rawglSupportDir = [appSupportDir stringByAppendingPathComponent:@"rawgl"];

        BOOL isDir;
        if (![fileManager fileExistsAtPath:rawglSupportDir isDirectory:&isDir]) {
            NSError *error = nil;
            if (![fileManager createDirectoryAtPath:rawglSupportDir withIntermediateDirectories:YES attributes:nil error:&error]) {
                mac_warning("Failed to create Application Support directory");
                if (error) {
                    printf("Error: %s\n", [[error localizedDescription] UTF8String]);
                }
                return "";
            }
        } else if (!isDir) {
            mac_warning("Application Support path exists but is not a directory");
            return "";
        }

        return std::string([rawglSupportDir UTF8String]);
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
