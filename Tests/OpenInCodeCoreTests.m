#import <Foundation/Foundation.h>
#include <stdlib.h>
#import "OpenInCodeCore.h"

static void assertTrue(BOOL condition, NSString *message)
{
    if (!condition) {
        NSLog(@"FAIL: %@", message);
        exit(1);
    }
}

int main(void)
{
    @autoreleasepool {
        NSArray<NSString *> *bundleIdentifiers = OICPreferredVSCodeBundleIdentifiers();
        assertTrue([bundleIdentifiers count] == 2, @"expected two VS Code channels");
        assertTrue([bundleIdentifiers[0] isEqualToString:OICVSCodeBundleIdentifier], @"stable VS Code must be preferred");
        assertTrue([bundleIdentifiers[1] isEqualToString:OICVSCodeInsidersBundleIdentifier], @"Insiders must be the fallback");

        assertTrue(OICPathForFinderURL(nil) == nil, @"nil URL must return nil");
        assertTrue(OICPathForFinderURL([NSURL URLWithString:@"https://example.com"]) == nil, @"non-file URL must return nil");

        NSString *temporaryRoot = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
        NSString *folderPath = [temporaryRoot stringByAppendingPathComponent:@"Project"];
        NSString *filePath = [folderPath stringByAppendingPathComponent:@"README.md"];
        NSString *packagePath = [temporaryRoot stringByAppendingPathComponent:@"Example.app"];
        NSString *directorySymlinkPath = [temporaryRoot stringByAppendingPathComponent:@"LinkedProject"];

        NSFileManager *fileManager = [NSFileManager defaultManager];
        assertTrue([fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil], @"create test folder");
        assertTrue([@"test" writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil], @"create test file");
        assertTrue([fileManager createDirectoryAtPath:packagePath withIntermediateDirectories:YES attributes:nil error:nil], @"create test package");
        assertTrue([fileManager createSymbolicLinkAtPath:directorySymlinkPath withDestinationPath:folderPath error:nil], @"create directory symlink");

        assertTrue([OICPathForFinderURL([NSURL fileURLWithPath:folderPath]) isEqualToString:folderPath], @"folder should open itself");
        assertTrue([OICPathForFinderURL([NSURL fileURLWithPath:filePath]) isEqualToString:folderPath], @"file should open its parent");
        assertTrue([OICPathForFinderURL([NSURL fileURLWithPath:packagePath]) isEqualToString:temporaryRoot], @"Finder package should open its parent");
        assertTrue([OICPathForFinderURL([NSURL fileURLWithPath:directorySymlinkPath]) isEqualToString:directorySymlinkPath], @"directory symlink should open the linked directory");
        assertTrue(OICPathForFinderURL([NSURL fileURLWithPath:[temporaryRoot stringByAppendingPathComponent:@"missing"]]) == nil, @"missing item must return nil");

        assertTrue([fileManager removeItemAtPath:temporaryRoot error:nil], @"remove test files");
        NSLog(@"OpenInCodeCoreTests: PASS");
    }

    return 0;
}
