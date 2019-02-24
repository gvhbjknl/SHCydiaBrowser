//
//  shFTPPanel.m
//  shRepoManager
//
//  Created by Shahin Katebi on 12/8/90.
//  Copyright (c) 1390 Idea Pardazan Seeb Co. LTD. All rights reserved.
//

#import "shFTPPanel.h"
@interface shFTPPanel()
{

}
@property (unsafe_unretained) IBOutlet NSTextField *titleLabel;
@property (unsafe_unretained) IBOutlet NSProgressIndicator *progressBar;
@property (unsafe_unretained) IBOutlet NSTextField *subtitleLabel;

//@property (strong) NSTask *task;
//@property (strong) NSFileHandle *fileHandler;
@property (unsafe_unretained) IBOutlet NSWindow *theWindow;
@end
@implementation shFTPPanel
@synthesize theWindow = _theWindow;
@synthesize titleLabel = _titleLabel;
@synthesize progressBar = _progressBar;
@synthesize subtitleLabel = _subtitleLabel;
//@synthesize task = _task;
//@synthesize fileHandler = _fileHandler;
- (id) init
{
    self = [super initWithWindowNibName:@"shFTPPanel_Window"];
    return self;
}
- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
-(void) processData: (NSData *) data
{
   NSString *txt = [[NSString alloc] initWithData:data 
                                 encoding:NSASCIIStringEncoding];
   NSString *text = [[[[[txt stringByReplacingOccurrencesOfString:@"#" withString:@""] stringByReplacingOccurrencesOfString:@"\t" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"%" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSLog(@"recieved: ||%@||",text);
    if([text doubleValue])
    {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // everything about UIKit place it here.
        self.subtitleLabel.stringValue = [NSString stringWithFormat:@"%1.1f%@", [text floatValue],@"%"];
        self.progressBar.doubleValue = [text doubleValue];
    });
    }
    else if([text rangeOfString:@"curl:"].location != NSNotFound)
    {
        NSAlert *theAlert = [[NSAlert alloc] init];
        [theAlert addButtonWithTitle:@"OK"];
        [theAlert setMessageText:@"Operation Failed!"];
        [theAlert setInformativeText:txt];
        [theAlert setAlertStyle:0];
        [theAlert runModal];
    }
}
- (void) runCommand: (NSString *) cmd withArguments: (NSArray *) args
{
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: cmd ];
	[task setArguments: args];
	NSData *inData = nil;
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
    [task setStandardError: pipe];
    
    NSFileHandle *fileHandle = [pipe fileHandleForReading];
    //[self.fileHandler readInBackgroundAndNotify];
    
    [task launch];
    
    while ((inData = [fileHandle availableData]) && [inData length]) {
        [self processData:inData];
    }
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
- (BOOL) uploadFileFromPath: (NSString *) sourcePath toPath: (NSString *) destinationPath
{
    [NSApp beginSheet:self.window modalForWindow: [NSApp mainWindow] modalDelegate:self didEndSelector:NULL contextInfo:nil];
    self.titleLabel.stringValue = [NSString stringWithFormat:@"Uploading '%@'...", [[sourcePath pathComponents] lastObject]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // do something in other thread
        [self runCommand:@"/usr/bin/curl" withArguments:[NSArray arrayWithObjects: @"-#", @"-T", sourcePath, destinationPath, nil]];
        dispatch_async(dispatch_get_main_queue(), ^{
            // everything about UIKit place it here.
            NSLog(@"done");

            //
            [NSApp stopModalWithCode:11];
            
            [self.window orderOut:nil];
        });
    });
    [NSApp endSheet:self.window returnCode:11];
    return  ([NSApp runModalForWindow:self.window] == 11)? YES: NO;
    //return
}
- (BOOL) downloadFileFromPath: (NSString *) sourcePath toPath: (NSString *) destinationPath
{
    [NSApp beginSheet:self.window modalForWindow: [NSApp mainWindow] modalDelegate:self didEndSelector:NULL contextInfo:nil];
    self.titleLabel.stringValue = [NSString stringWithFormat:@"Dowloading '%@'...", [[sourcePath pathComponents] lastObject]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // do something in other thread
        [self runCommand:@"/usr/bin/curl" withArguments:[NSArray arrayWithObjects: @"-#", @"-O", destinationPath ,sourcePath, nil]];
        dispatch_async(dispatch_get_main_queue(), ^{
            // everything about UIKit place it here.
            NSLog(@"done");
            
            [self.window orderOut:nil];
            //[NSApp stopModalWithCode:11];
            [NSApp endSheet:self.window returnCode:11];
        });
    });
    return YES;// ([NSApp runModalForWindow:self.window] == 11)? YES: NO;
}
@end
