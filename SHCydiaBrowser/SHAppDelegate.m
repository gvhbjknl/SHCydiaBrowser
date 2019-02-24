//
//  iPNAppDelegate.m
//  CydiaNerd
//
//  Created by Shahin Katebi on 12/24/90.
//  Copyright (c) 1390 Idea Pardazan Seeb Co. LTD. All rights reserved.
//

#import "SHAppDelegate.h"

@implementation SHAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}
- (void)windowWillClose:(NSNotification *)aNotification {
	[NSApp terminate:self];
}
- (IBAction)showAbout:(NSMenuItem *)sender {
    NSAlert *theAlert = [[NSAlert alloc] init];
    [theAlert addButtonWithTitle:@"OK"];
    [theAlert setMessageText:@"CyNerd"];
    [theAlert setInformativeText:@"Developed by: Shahin Katebi\non behalf of iPhone Nerd Inc."];
    [theAlert setAlertStyle:NSInformationalAlertStyle];
    [theAlert runModal];
}

@end
