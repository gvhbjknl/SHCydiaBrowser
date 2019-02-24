//
//  shFileStream.m
//  CydiaNerd
//
//  Created by Shahin Katebi on 12/28/90.
//  Copyright (c) 1390 Idea Pardazan Seeb Co. LTD. All rights reserved.
//

#import "shFileStream.h"

@interface shFileStream () <NSURLDownloadDelegate>
@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSProgressIndicator *singleProgressBar;
@property (weak) IBOutlet NSTextField *subtitleLabel;
@property (nonatomic, strong) NSURLDownload *download;
@property (strong) IBOutlet NSProgressIndicator *overallProgressBar;
@property (strong) IBOutlet NSTextField *progressLabel;

@end

@implementation shFileStream
@synthesize titleLabel = _titleLabel;
@synthesize singleProgressBar = _singleProgressBar;
@synthesize subtitleLabel = _subtitleLabel;
@synthesize operation = _operation;
@synthesize parameters = _parameters;
@synthesize delegate = _delegate;
@synthesize download = _download;
@synthesize overallProgressBar = _overallProgressBar;
@synthesize progressLabel = _progressLabel;

- (id) initWithOperationType: (NSString *) type andParameters: (NSArray *) params
{
   self = [super initWithWindowNibName:@"shFileStreamPanel"];
    self.operation = type;
    self.parameters = params;
    return self;
}
- (void) downloadFileWithURL: (NSString *) url andDestinationFolder: (NSString *) path
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    self.titleLabel.stringValue =  [NSString stringWithFormat: @"Connecting to file: %@...", [url lastPathComponent]];
    [request setValue:@"Telesphoreo APT-HTTP/1.0.592" forHTTPHeaderField:@"User-Agent"];
    self.singleProgressBar.doubleValue = 0;
    self.download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
    [self.download setDestination:[path stringByAppendingPathComponent:[url lastPathComponent]] allowOverwrite:YES];
}
-(void) executeActionWithWindow: (NSWindow *) window
{
    [NSApp beginSheet:self.window modalForWindow: window modalDelegate:self didEndSelector:NULL contextInfo:nil];
    if([self.operation isEqualToString:SHFILESTREAM_OPERATION_HTTPDOWNLOAD])
    {
        [self downloadFileWithURL:[[self.parameters objectAtIndex:0] objectAtIndex:0] andDestinationFolder:[self.parameters objectAtIndex:1]];
        self.overallProgressBar.maxValue = [[self.parameters objectAtIndex:0] count];
        self.overallProgressBar.doubleValue = 0;
        self.subtitleLabel.stringValue = [NSString stringWithFormat: @"Processing file %0.0f of %li", self.overallProgressBar.doubleValue + 1, [[self.parameters objectAtIndex:0] count]];
    }
}
-(void)awakeFromNib
{
    //[self executeAction];
}
- (IBAction)cancel:(NSButton *)sender {
    
    //[self.download cancel];
    
    [self.delegate fileStream:self operationDidFinishedWithResult:SHFILESTREAM_RESULT_CANCELED];
    [NSApp endSheet:self.window];
    [NSApp stopModal];
    [self.window orderOut:nil];
    @try {
         [self.download cancel];
    }
    @catch (NSException *exception) {
        ;
    }
    @finally {
        ;
    }
   
}
#pragma mark - nsurldownload delegate
- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    NSAlert *theAlert = [[NSAlert alloc] init];
    [theAlert addButtonWithTitle:@"OK"];
    [theAlert setMessageText:@"Operation Failed"];
    [theAlert setInformativeText:[NSString stringWithFormat: @"Error:\n%@",error]];
    [theAlert setAlertStyle:0];
    [theAlert runModal];
    NSLog(@"failed: %@", error);
}
- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
    self.singleProgressBar.doubleValue += length;
    self.progressLabel.stringValue = [NSString stringWithFormat: @"%1.2f KB of %1.2f KB",self.singleProgressBar.doubleValue/ 1024, self.singleProgressBar.maxValue/1024];
    NSLog(@"data recieved: %lu", length);
}
- (void)downloadDidFinish:(NSURLDownload *)download
{
    self.titleLabel.stringValue = @"Finished.";
    self.overallProgressBar.doubleValue +=1;
    self.progressLabel.stringValue = @"";
    if(self.overallProgressBar.doubleValue < self.overallProgressBar.maxValue)
    {
        self.subtitleLabel.stringValue = [NSString stringWithFormat: @"Processing file %0.0f of %lu",  self.overallProgressBar.doubleValue + 1, (unsigned long)[[self.parameters objectAtIndex:0] count]];
        // do the next
        [self downloadFileWithURL:[[self.parameters objectAtIndex:0] objectAtIndex:self.overallProgressBar.doubleValue] andDestinationFolder:[self.parameters objectAtIndex:1]];
    }else {
        [self.delegate fileStream:self operationDidFinishedWithResult:SHFILESTREAM_RESULT_FINISHED];
        sleep(2);
        [NSApp endSheet:self.window];
        [NSApp stopModal];
        [self.window orderOut:nil];
    }
    NSLog(@"finished.");
    
}
- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
    self.singleProgressBar.maxValue = response.expectedContentLength;
    NSLog(@"response recieved: %lld", response.expectedContentLength );
}
- (void)downloadDidBegin:(NSURLDownload *)download{
    self.titleLabel.stringValue = [NSString stringWithFormat: @"File: %@...", [download.request.URL lastPathComponent]];
}
@end
