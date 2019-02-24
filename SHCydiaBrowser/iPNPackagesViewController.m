//
//  iPNPackagesViewController.m
//  CydiaNerd
//
//  Created by Shahin Katebi on 12/26/90.
//  Copyright (c) 1390 Idea Pardazan Seeb Co. LTD. All rights reserved.
//

#import "iPNPackagesViewController.h"
#import "iPNSourcesViewController.h"
#import "shStrings.h"
#import "shDebian.h"
#import "shFileStream.h"
@interface iPNPackagesViewController () <NSTableViewDataSource,NSWindowDelegate, NSComboBoxDataSource, NSComboBoxDelegate, NSTextFieldDelegate>
@property (weak) IBOutlet NSTableView *tableView;
@property (strong, nonatomic) NSArray *packages;
@property (strong, nonatomic) NSArray *allPackages;
@property (strong, nonatomic) IBOutlet NSMutableSet *sections;
@property (weak) IBOutlet NSComboBox *sectionsComboBox;
@end

@implementation iPNPackagesViewController
@synthesize tableView = _tableView;
@synthesize packages = _packages;
@synthesize sections = _sections;
@synthesize sectionsComboBox = _sectionsComboBox;
@synthesize allPackages = _allPackages;
- (NSMutableSet *)sections
{
    if(!_sections)
    {
        _sections = [NSMutableSet set];
    }
    return _sections;
}
- (IBAction)searchPackage:(id)sender
{
    NSMutableArray *arr = [NSMutableArray array];
    [self.allPackages enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop)
     {
         if([[obj objectForKey:@"Section"] isEqualToString:[[self.sections allObjects] objectAtIndex:((int)index)-1]])
         {
             [arr addObject:obj];
         }
     }];
    self.packages = arr;

}
- (void) reloadPackagesFromFiles
{
    if(!self.allPackages)
    {
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSDirectoryEnumerator *dirEnum =
        [fileMgr enumeratorAtPath:[shDebian workingFolderWithSubfolder:SHCYDIASOURCE_DATABASES]];
        
        NSString *file;
        NSMutableArray *packagesList = [NSMutableArray array];
        while (file = [dirEnum nextObject]) {
            if ([[file pathExtension] isEqualToString: @"packages"]) {
                // process the document
                file = [[shDebian workingFolderWithSubfolder:SHCYDIASOURCE_DATABASES] stringByAppendingPathComponent: file];
                NSLog(@"Processing file %@", file);//
                [packagesList addObjectsFromArray: [shDebian parsePackagesFile: file]];
            }
        }
        self.allPackages = packagesList;
    }
    // check section
    
    int index = (unsigned int)[self.sectionsComboBox indexOfSelectedItem];
    if(index != -1 && index!= 0)
    {
        NSMutableArray *arr = [NSMutableArray array];
        [self.allPackages enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop)
         {
             if([[obj objectForKey:@"Section"] isEqualToString:[[self.sections allObjects] objectAtIndex:index-1]])
             {
                 [arr addObject:obj];
             }
         }];
        self.packages = arr;
    }
    else
    {
        self.packages = self.allPackages;
    }
    [self.tableView setDataSource:self];
    [self.tableView reloadData];
}
- (NSString *) retrieveDownloadURLFromRowIndex: (NSInteger) idx
{
    NSDictionary *row =  [self.packages objectAtIndex:idx];
    return [NSString stringWithFormat:@"http://%@", [[[[row objectForKey:@"shSourceRepo"] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@"/"] stringByAppendingPathComponent: [[[row objectForKey:@"Filename"] stringByReplacingOccurrencesOfString:@"./" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] ]];
}
- (NSArray *)packages
{
    if(!_packages)
    {
        _packages = [NSMutableArray array];
        [self reloadPackagesFromFiles];
    }
    return _packages;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
- (IBAction)openDownloadsFolder:(NSButton *)sender {
    //reach here
    NSString *folder =[shDebian workingFolderWithSubfolder:SHCYDIASOURCE_DOWNLOADS];
    NSLog(@"reach here: %@", folder);
    [[NSWorkspace sharedWorkspace] openFile:folder]; 
}
- (void) sourcesUpdated
{
    self.allPackages = nil;
    [self reloadPackagesFromFiles];
}
- (void)awakeFromNib
{
    [self reloadPackagesFromFiles];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourcesUpdated) name:@"sourcesSaved" object:nil];
}
- (void)windowWillClose:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSApp terminate:self];
}
- (IBAction)downloadSelectedItem:(NSButton *)sender {
    
    NSIndexSet *selectedRows = [self.tableView selectedRowIndexes];
    if(selectedRows.count >0)
    {
        NSMutableArray *urls = [NSMutableArray array];
        [selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
            [urls addObject:[self retrieveDownloadURLFromRowIndex:idx]];
        }];
        NSLog(@"urls: %@", urls);
        
        shFileStream *fs = [[shFileStream alloc] initWithOperationType:SHFILESTREAM_OPERATION_HTTPDOWNLOAD andParameters:[NSArray arrayWithObjects:urls , [shDebian workingFolderWithSubfolder:SHCYDIASOURCE_DOWNLOADS], nil]];
        [fs executeActionWithWindow:self.view.window];
    }
}
#pragma mark - dataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.packages.count;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *rowData = [self.packages objectAtIndex:row];
    
    if([tableColumn.identifier isEqualToString:@"Section"])
    {
         NSString *section = [rowData objectForKey:@"Section"];
        if(section && ![self.sections containsObject:[rowData objectForKey:@"Section"]])
        {
            [self.sections addObject:section];
            [self.sectionsComboBox reloadData];
        }
    }
    if(row + 1 == self.packages.count)
    {
        
    }
    
    NSCell *cell = [[NSCell alloc] initTextCell:([rowData objectForKey:tableColumn.identifier])? [rowData objectForKey:tableColumn.identifier]: @"(null)"];
    return cell;
    
}
- (IBAction)selectAll:(id)sender {
    [self.tableView selectAll:self];
}
- (IBAction)deselectAll:(id)sender
{
    [self.tableView deselectAll:self];
}

#pragma mark - combobox datasource
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return self.sections.count+1;
}
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    if(index == 0)
    {
       return @"-- All --";
    }
    else
    {
        return [[self.sections allObjects] objectAtIndex:index-1]; 
    }
       
}
#pragma mark - combobox delegate
- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    [self reloadPackagesFromFiles];
}
@end
