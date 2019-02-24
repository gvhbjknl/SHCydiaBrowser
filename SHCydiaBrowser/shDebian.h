//
//  shDebian.h
//  shRepoManager
//  version 1.5
//  Created by Shahin Katebi on 12/3/90.
//  Copyright (c) 1390 Idea Pardazan Seeb Co. LTD. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface shDebian : NSObject
{
}
#define SHCYDIASOURCE_HOMEFOLDER @"shCydiaBrowser"
#define SHCYDIASOURCE_DATABASES @"db"
#define SHCYDIASOURCE_DOWNLOADS @"Downloads"

#define SHDEBIAN_WORKINGFOLDER_ROOT @""
#define SHDEBIAN_WORKINGFOLDER_BUILD @"Build"
#define SHDEBIAN_WORKINGFOLDER_REPO @"repo"
#define SHDEBIAN_WORKINGFOLDER_REPODEB @"repo/debs"
#define SHDEBIAN_WORKINGFOLDER_REPODEPICTION @"repo/depiction"
#define SHDEBIAN_WORKINGFOLDER_BUILDARCHIVE @"BuildArchive"
#define SHDEBIAN_WORKINGFOLDER_OTHERFILES @"Other"
#define IPHONENERD_FTPROOT @""

+ (void) prepareTools;
+ (NSString *) workingFolderWithSubfolder: (NSString *) subfolder;
+ (NSString *) runCommand: (NSString *) cmd withArguments: (NSArray *) args;
+ (NSString *) createDebPackageWithFolderName: (NSString *) packageFolderName thenMoveIt: (BOOL) move;
+ (NSString *) extractDebPackageWithPath: (NSString *) pathToDebFile;
+ (BOOL) uploadFileWithPath: (NSString *) filePath toPath: (NSString *) pathOnServer silent: (BOOL) silent;
+ (BOOL) downloadFileWithPath: (NSString *) pathOnServer  toPath: (NSString *) filePath silent: (BOOL) silent;
+ (BOOL) uploadDebPackageWithName: (NSString *) packageName  silent: (BOOL) silent;
+ (NSDictionary *) parseControlFileWithPath: (NSString *) filePath;
+ (BOOL) writeControlFileWithData: (NSDictionary *) data toPath: (NSString *) filePath;
+ (BOOL) createLocalPackagesListFileAndUpdateServer: (BOOL) shouldUpdate;
+ (void) processPackagesFile: (NSString *)file1 andMergeWithPackagesFile: (NSString*) file2 thenSaveItTo: (NSString *) destination;
+ (NSMutableArray *) parsePackagesFile: (NSString *)file;
@end

