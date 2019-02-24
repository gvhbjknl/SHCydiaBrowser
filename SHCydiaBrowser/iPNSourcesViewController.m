//
//  iPNSourcesViewController.m
//  CydiaNerd
//
//  Created by Shahin Katebi on 12/26/90.
//  Copyright (c) 1390 Idea Pardazan Seeb Co. LTD. All rights reserved.
//

#import "iPNSourcesViewController.h"
#import "shDebian.h"
#import "NSData+Bzip2.h"
#import "shStrings.h"

@interface iPNSourcesViewController () <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTextField *sourceUrl;
@property (weak) IBOutlet NSTableView *tableView;
@property (strong, nonatomic) NSMutableArray *sources;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSTabView *tabView;
@property (strong, nonatomic) NSMutableDictionary  *workedSources;
@property (weak) IBOutlet NSButton *shouldFindAutomatically;
@end
@implementation iPNSourcesViewController
@synthesize sources = _sources;
@synthesize progressBar = _progressBar;
@synthesize tabView = _tabView;
@synthesize sourceUrl = _sourceUrl;
@synthesize tableView = _tableView;
@synthesize workedSources = _workedSources;
@synthesize shouldFindAutomatically = _shouldFindAutomatically;

- (NSMutableDictionary *)workedSources
{
    if(!_workedSources)
    {
        _workedSources = [NSMutableDictionary dictionary];
    }
    return _workedSources;
}

- (NSString *) sourcesDbPath
{
    return [[shDebian workingFolderWithSubfolder:SHCYDIASOURCE_DATABASES] stringByAppendingPathComponent:@"sources.db"];
}
- (NSArray *)sources
{
    if(!_sources)
    {
 
        if([[NSFileManager defaultManager] fileExistsAtPath:[self sourcesDbPath]])
        {
            _sources = [NSMutableArray arrayWithContentsOfFile:[self sourcesDbPath]];
        }
        else {
            _sources = [NSMutableArray array];
            [_sources writeToFile:[self sourcesDbPath] atomically:NO];
        }
        
        
    }
    return _sources;
}
- (void)awakeFromNib
{
    [self.tableView setDataSource:self];
}
- (void)setSources:(NSMutableArray *)sources
{
    _sources = sources;
    [_sources writeToFile:[self sourcesDbPath] atomically:NO];
}

- (void) saveSources
{
    [self.sources  writeToFile:[self sourcesDbPath] atomically:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sourcesSaved" object:nil];
}
- (BOOL) refreshSource: (NSDictionary *) dict
{
    NSString *packagesFileName = [[shDebian workingFolderWithSubfolder:SHCYDIASOURCE_DATABASES] stringByAppendingPathComponent:[dict objectForKey:SHSOURCE_PACKAGEFILE]];

    NSString *packagesURL = [dict objectForKey:SHSOURCE_URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:packagesURL]]; // Telesphoreo APT-HTTP/1.0.592
    [request setValue:@"Telesphoreo APT-HTTP/1.0.592" forHTTPHeaderField:@"User-Agent"];
    NSData *result;
    NSLog(@"request url: %@",request.URL);
   
    NSError *error;
    result = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
    if(result.length >0)
    {
        if([[dict objectForKey:SHSOURCE_FORMAT] isEqualToString:@""])
            [result writeToFile:packagesFileName atomically:NO];
        if([[dict objectForKey:SHSOURCE_FORMAT] isEqualToString:@"bz2"])
            [[result bunzip2] writeToFile:packagesFileName atomically:NO];
        if([[dict objectForKey:SHSOURCE_FORMAT] isEqualToString:@"gz"])
            [[result bunzip2] writeToFile:packagesFileName atomically:NO];
    }

    return (result) ? YES : NO;
}
- (NSString *) timestamp
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd 'at' HH:mm"];
    return [dateFormatter stringFromDate:[NSDate date]];
}
- (void) addSourceObjectWithUrl: (NSString *) packagesURL andWithFileName: (NSString *) packagesFileName
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:packagesURL forKey:SHSOURCE_URL];
    [dict setValue:[self timestamp] forKey:SHSOURCE_LASTUPDATE];
    [dict setValue:[packagesURL pathExtension] forKey:SHSOURCE_FORMAT];
    [dict setValue:[packagesFileName lastPathComponent] forKey: SHSOURCE_PACKAGEFILE ];
    
    [self.sources addObject:dict];
    [self saveSources];
    [self.tableView reloadData];

}
- (void) removeSourceObjectAtIndex: (NSInteger) idx
{
    
    [self.sources removeObjectAtIndex:idx];
    [self saveSources];
    [self.tableView reloadData];
    
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
- (NSString *) addAndDownloadSourceFromUrl: (NSString *) url
{
    NSString *packagesFileName = [[shDebian workingFolderWithSubfolder:SHCYDIASOURCE_DATABASES] stringByAppendingPathComponent:[NSString stringWithFormat: @"%@.packages", [[url stringByReplacingOccurrencesOfString:@"http://" withString:@"" ] stringByReplacingOccurrencesOfString:@"/" withString:@"_"]]]; //[[url pathComponents] objectAtIndex:1]
    NSLog(@"urL: %@",url);
    NSString *packagesURL = ([self.shouldFindAutomatically state] == NSOnState) ? [url stringByAppendingString:@"/Packages"] : url;
    if([self.shouldFindAutomatically state] == NSOnState)
    {
        NSError *error;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:packagesURL]]; // Telesphoreo APT-HTTP/1.0.592
        [request setValue:@"Telesphoreo APT-HTTP/1.0.592" forHTTPHeaderField:@"User-Agent"];
        NSLog(@"request url: %@",request.URL);
        NSURLResponse *response;
        NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if(result.length == 0 || ![[response MIMEType] isEqualToString:@"text/plain"])
        {
            request.URL = [NSURL URLWithString:[packagesURL stringByAppendingString:@".bz2"]];
            NSLog(@"request url: %@",request.URL);
            result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            NSLog(@"ERRORR: %@",[response MIMEType]);
            if(result.length == 0 || ![[response MIMEType] hasPrefix:@"application/"])
            {
                request.URL = [NSURL URLWithString:[packagesURL stringByAppendingString:@".gz"]];
                NSLog(@"request url: %@",request.URL);
                result = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
                
                if(!error)
                {
                    NSLog(@"ERRORR: %@",error);
                    return @"connectionError";
                }
                if(result.length == 0)
                {
                    return @"notValid";
                }
                else
                {
                    //do gz it
                    [[result bunzip2] writeToFile:packagesFileName atomically:NO];
                    [self addSourceObjectWithUrl:[request.URL description] andWithFileName:packagesFileName];
                    return @"OK";
                }
            }
            else {
                // do bzip it
                [[result bunzip2] writeToFile:packagesFileName atomically:NO ];
                [self addSourceObjectWithUrl:[request.URL description] andWithFileName:packagesFileName];
                return @"OK";
            }
        }else {
            //just save it
             
            [result writeToFile:packagesFileName atomically:NO];
            [self addSourceObjectWithUrl:packagesURL andWithFileName:packagesFileName];
         
            return @"OK";
        }
    }else {
        [self addSourceObjectWithUrl:packagesURL andWithFileName:packagesFileName];
        [self refreshSource:[self.sources lastObject]];
        return @"OK";
    }
}
- (IBAction)addSource:(NSButton *)sender {
    NSString *title = [sender.title copy];
    sender.enabled =NO;
    sender.title = @"Wait...";
    [self.progressBar setIndeterminate:YES];
    [self.progressBar startAnimation:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // do something in other thread
        
                
        dispatch_async(dispatch_get_main_queue(), ^{
            // everything about UIKit place it here.
            NSString * result = [self addAndDownloadSourceFromUrl: self.sourceUrl.stringValue];
            if([result isEqualToString: @"OK"])
            {
                sender.title = title;
                sender.enabled = YES;
                [self.progressBar stopAnimation:self];
                self.sourceUrl.stringValue = @"http://";
                
            }else {
                sender.title = title;
                sender.enabled = YES;
                [self.progressBar stopAnimation:self];
                
                NSAlert *theAlert = [[NSAlert alloc] init];
                [theAlert addButtonWithTitle:@"OK"];
                [theAlert setMessageText:@"Source Error"];
                [theAlert setInformativeText:@"Source is not valid."];
                if([result isEqualToString: @"connectionError"]){
                    [theAlert setMessageText:@"Connection Error"];
                    [theAlert setInformativeText:@"Check your network connection."];
                }
                [theAlert setAlertStyle:0];
                [theAlert runModal];
            }
        });
    });
}
- (IBAction)removeSource:(NSButton *)sender {
    if([self.tableView selectedRowIndexes].count>0)
    {
        [[NSFileManager defaultManager] removeItemAtPath: [[shDebian workingFolderWithSubfolder:SHCYDIASOURCE_DATABASES] stringByAppendingPathComponent: [[self.sources objectAtIndex:[self.tableView selectedRow]] objectForKey:SHSOURCE_PACKAGEFILE]] error:NULL];
        [self removeSourceObjectAtIndex: [self.tableView selectedRow]];
    }
}
- (IBAction)refreshAllSources:(NSButton *)sender {
    [self.tabView selectLastTabViewItem:self];
    [self.tableView setDataSource:self];
    [self.progressBar setIndeterminate:NO];
    [self.progressBar setDisplayedWhenStopped:YES];
    self.progressBar.maxValue = self.sources.count;
    NSString *title = [sender.title copy];
    [sender setEnabled:NO];
    [sender setTitle:@"Updating..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger __block idx = 0;
        for (NSDictionary * dict in [self.sources mutableCopy]) {
            
            [self.workedSources setObject:@"updating..." forKey:[NSString stringWithFormat:@"%ld", idx]];
            
            BOOL result = [self refreshSource:dict];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSLog(@"index is: %ld", idx);
                if(result)
                {
                    //[self.workedSources replaceObjectAtIndex:idx withObject:@"done."];
                    [self.workedSources setObject:@"done." forKey:[NSString stringWithFormat:@"%ld", idx]];
                    NSMutableDictionary *theRow = [[self.sources objectAtIndex:idx] mutableCopy];
                    [theRow setValue:[self timestamp] forKey:SHSOURCE_LASTUPDATE];
                    [self.sources replaceObjectAtIndex:idx withObject:theRow];
                    [self saveSources];
                    [self.tableView reloadData];
                    
                }else {
                    [self.workedSources setObject:@"failed." forKey:[NSString stringWithFormat:@"%ld", idx]];
                    [self.tableView reloadData];
                    NSAlert *theAlert = [[NSAlert alloc] init];
                    [theAlert addButtonWithTitle:@"OK"];
                    [theAlert setMessageText:@"Failed"];
                    [theAlert setInformativeText:[NSString stringWithFormat: @"Update Source failed for source: %@",[dict objectForKey: SHSOURCE_URL]]];
                    [theAlert setAlertStyle:0];
                    [theAlert runModal];
                }
                self.progressBar.doubleValue =idx+1;
                idx++;
            });
        }
        // done
        [self.progressBar setDisplayedWhenStopped:NO];
        [sender setEnabled:YES];
        [sender setTitle:title];
        
    });

    
}

#pragma mark - dataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.sources.count;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *rowData = [self.sources objectAtIndex:row];
    
    NSCell *cell = [[NSCell alloc] initTextCell:([tableColumn.identifier isEqualToString:@"Status"])? ([self.workedSources objectForKey:[NSString stringWithFormat:@"%ld", row]])?[self.workedSources objectForKey:[NSString stringWithFormat:@"%ld", row]]:@"idle" : [rowData objectForKey:tableColumn.identifier]];
    return cell;
}
@end
