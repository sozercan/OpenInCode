#import <Foundation/Foundation.h>

extern NSString * const OICVSCodeBundleIdentifier;
extern NSString * const OICVSCodeInsidersBundleIdentifier;

NSArray<NSString *> *OICPreferredVSCodeBundleIdentifiers(void);
NSString *OICPathForFinderURL(NSURL *url);
