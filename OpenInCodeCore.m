#import "OpenInCodeCore.h"

NSString * const OICVSCodeBundleIdentifier = @"com.microsoft.VSCode";
NSString * const OICVSCodeInsidersBundleIdentifier = @"com.microsoft.VSCodeInsiders";

NSArray<NSString *> *OICPreferredVSCodeBundleIdentifiers(void)
{
    return @[OICVSCodeBundleIdentifier, OICVSCodeInsidersBundleIdentifier];
}

NSString *OICPathForFinderURL(NSURL *url)
{
    if (url == nil || ![url isFileURL]) {
        return nil;
    }

    NSNumber *isAliasFile = nil;
    NSNumber *isSymbolicLink = nil;
    [url getResourceValue:&isAliasFile forKey:NSURLIsAliasFileKey error:nil];
    [url getResourceValue:&isSymbolicLink forKey:NSURLIsSymbolicLinkKey error:nil];
    if ([isAliasFile boolValue] && ![isSymbolicLink boolValue]) {
        NSData *bookmark = [NSURL bookmarkDataWithContentsOfURL:url error:nil];
        if (bookmark == nil) {
            return nil;
        }

        NSURL *resolvedURL = [NSURL URLByResolvingBookmarkData:bookmark
                                                       options:NSURLBookmarkResolutionWithoutUI
                                                 relativeToURL:nil
                                           bookmarkDataIsStale:nil
                                                         error:nil];
        if (resolvedURL == nil) {
            return nil;
        }
        url = resolvedURL;
    }

    NSString *path = [[url path] stringByExpandingTildeInPath];
    if ([path length] == 0) {
        return nil;
    }

    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
        return nil;
    }

    NSURL *packageCheckURL = [url URLByResolvingSymlinksInPath];
    NSNumber *isPackageValue = nil;
    [packageCheckURL getResourceValue:&isPackageValue forKey:NSURLIsPackageKey error:nil];
    BOOL isPackage = [isPackageValue boolValue];

    if (!isDirectory || isPackage) {
        path = [path stringByDeletingLastPathComponent];
    }

    return [path length] > 0 ? path : nil;
}
