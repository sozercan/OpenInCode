//
//  main.m
//  Open in Code
//
//  Created by Sertac Ozercan on 7/9/2016.
//  Copyright Sertac Ozercan 2016. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>
#import "Finder.h"
#import "OpenInCodeCore.h"

static NSString * const FinderAutomationPermissionMessage = @"Open the Automation privacy settings and allow Open in Code to control Finder, then try again.";

@interface OICScriptingBridgeErrorHandler : NSObject <SBApplicationDelegate> {
    NSError *_lastError;
}

@property(nonatomic, retain) NSError *lastError;

@end

@implementation OICScriptingBridgeErrorHandler

@synthesize lastError = _lastError;

- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{
    (void)event;
    [self setLastError:error];
    return nil;
}

- (void)dealloc
{
    [_lastError release];
    [super dealloc];
}

@end

static void showErrorAlert(NSString *message, NSString *informativeText)
{
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [NSApp activateIgnoringOtherApps:YES];

    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setAlertStyle:NSAlertStyleCritical];
    [alert setMessageText:message];
    [alert setInformativeText:informativeText];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

static NSString *pathToFrontFinderLocation(NSString **errorMessage)
{
    @try {
        FinderApplication *finder = [SBApplication applicationWithBundleIdentifier:@"com.apple.Finder"];
        OICScriptingBridgeErrorHandler *errorHandler = [[[OICScriptingBridgeErrorHandler alloc] init] autorelease];
        [finder setDelegate:errorHandler];

        FinderItem *target = [(NSArray *)[[finder selection] get] firstObject];

        if (target == nil) {
            target = [[[[finder FinderWindows] firstObject] target] get];
        }

        NSString *targetURLString = [target URL];
        if ([targetURLString length] == 0) {
            if (errorMessage != NULL) {
                if ([errorHandler lastError] != nil) {
                    *errorMessage = FinderAutomationPermissionMessage;
                } else {
                    *errorMessage = @"Open a Finder window for a local folder and try again.";
                }
            }
            return nil;
        }

        NSString *path = OICPathForFinderURL([NSURL URLWithString:targetURLString]);
        if ([path length] == 0 && errorMessage != NULL) {
            *errorMessage = @"The selected Finder item does not have an accessible local path.";
        }

        return path;
    }
    @catch (NSException *exception) {
        if (errorMessage != NULL) {
            *errorMessage = FinderAutomationPermissionMessage;
        }
        return nil;
    }
}

static BOOL openPathInPreferredVSCode(NSString *path, NSString **errorMessage)
{
    if ([path length] == 0) {
        if (errorMessage != NULL) {
            *errorMessage = @"No folder path was available to open.";
        }
        return NO;
    }

    NSURL *folderURL = [NSURL fileURLWithPath:path isDirectory:YES];
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    for (NSString *bundleIdentifier in OICPreferredVSCodeBundleIdentifiers()) {
        NSURL *applicationURL = [workspace URLForApplicationWithBundleIdentifier:bundleIdentifier];
        if (applicationURL == nil) {
            continue;
        }

        NSWorkspaceOpenConfiguration *configuration = [NSWorkspaceOpenConfiguration configuration];
        [configuration setActivates:YES];
        [configuration setPromptsUserIfNeeded:YES];
        [configuration setAllowsRunningApplicationSubstitution:NO];

        dispatch_semaphore_t completion = dispatch_semaphore_create(0);
        __block BOOL opened = NO;
        __block NSString *attemptError = nil;

        [workspace openURLs:@[folderURL]
       withApplicationAtURL:applicationURL
              configuration:configuration
          completionHandler:^(NSRunningApplication *application, NSError *error) {
              opened = application != nil && error == nil;
              if (error != nil) {
                  attemptError = [[error localizedDescription] copy];
              }
              dispatch_semaphore_signal(completion);
          }];

        dispatch_semaphore_wait(completion, DISPATCH_TIME_FOREVER);
#if !OS_OBJECT_USE_OBJC
        dispatch_release(completion);
#endif

        if (opened) {
            [attemptError release];
            return YES;
        }

        if (errorMessage != NULL) {
            if ([attemptError length] > 0) {
                *errorMessage = [attemptError autorelease];
                attemptError = nil;
            } else {
                *errorMessage = @"Visual Studio Code could not open the selected folder.";
            }
        }

        [attemptError release];
        return NO;
    }

    if (errorMessage != NULL) {
        *errorMessage = @"Install Visual Studio Code or Visual Studio Code Insiders, then try again.";
    }
    return NO;
}

int main(int argc, char *argv[])
{
    @autoreleasepool {
        NSString *finderError = nil;
        NSString *path = pathToFrontFinderLocation(&finderError);

        if ([path length] == 0) {
            showErrorAlert(@"Couldn’t read the Finder location", finderError ?: @"Open a Finder window and try again.");
            return 1;
        }

        NSString *launchError = nil;
        if (!openPathInPreferredVSCode(path, &launchError)) {
            showErrorAlert(@"Couldn’t open Visual Studio Code", launchError ?: @"The application could not be launched.");
            return 2;
        }

        return 0;
    }
}
