//
//  shDebian.m
//  shRepoManager
//
//  Created by Shahin Katebi on 12/3/90.
//  Copyright (c) 1390 Idea Pardazan Seeb Co. LTD. All rights reserved.
//

#import "shDebian.h"
#import "shFTPPanel.h"

@implementation shDebian


+ (NSString *) workingFolderWithSubfolder: (NSString *) subfolder
{
    NSString *folderAddress = [NSString pathWithComponents:[NSArray arrayWithObjects:NSHomeDirectory(), SHCYDIASOURCE_HOMEFOLDER, nil]];
    if(![subfolder isEqualToString:SHDEBIAN_WORKINGFOLDER_ROOT])
    {
        folderAddress = [folderAddress stringByAppendingPathComponent:subfolder]; 
    }
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if(![fileMgr fileExistsAtPath:folderAddress isDirectory:nil])
        [fileMgr createDirectoryAtPath:folderAddress withIntermediateDirectories:YES attributes:nil error:NULL];
    return folderAddress;
}
+ (NSString *) runCommand: (NSString *) cmd withArguments: (NSArray *) args
{
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: cmd ];
    [task setCurrentDirectoryPath:[shDebian workingFolderWithSubfolder:SHDEBIAN_WORKINGFOLDER_ROOT]];
	[task setArguments: args];
	
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	
	NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    [task waitUntilExit];
    NSData *data;
    data = [file readDataToEndOfFile];
    return [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

}
+ (NSString *) createDebPackageWithFolderName: (NSString *) packageFolderName thenMoveIt: (BOOL) move
{
    NSString *folderPath = [[shDebian workingFolderWithSubfolder:SHDEBIAN_WORKINGFOLDER_BUILD] stringByAppendingPathComponent: packageFolderName];
    NSString *archiveFolderPath = [[shDebian workingFolderWithSubfolder:SHDEBIAN_WORKINGFOLDER_BUILDARCHIVE] stringByAppendingPathComponent: packageFolderName];
    NSString *repoDebPath = [[shDebian workingFolderWithSubfolder:SHDEBIAN_WORKINGFOLDER_REPODEB] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", packageFolderName]];
    
    if(![folderPath isEqualToString: @".DS_Store"])
    {
        [shDebian runCommand:@"/sw/bin/dpkg-deb" withArguments:[NSArray arrayWithObjects: @"-b", folderPath, repoDebPath , nil]];
        if(move){
            [[NSFileManager defaultManager] moveItemAtPath:folderPath toPath:archiveFolderPath error: NULL];
        }
        return [NSString stringWithFormat:(move? @"%@ created and moved." : @"%@ created."), packageFolderName];
    }
    else
    {
        return @"";
    }
}
+ (NSString *) extractDebPackageWithPath: (NSString *) pathToDebFile
{
    NSString *folderPath = [[shDebian workingFolderWithSubfolder:SHDEBIAN_WORKINGFOLDER_BUILD] stringByAppendingPathComponent: [[pathToDebFile pathComponents] lastObject]];
    [[NSFileManager defaultManager] createDirectoryAtPath:[folderPath stringByAppendingPathComponent:@"DEBIAN"] withIntermediateDirectories:YES attributes:nil error:NULL];
    [shDebian runCommand:@"/sw/bin/dpkg-deb" withArguments:[NSArray arrayWithObjects: @"-e", pathToDebFile, [folderPath stringByAppendingPathComponent:@"DEBIAN"] , nil]];
    [shDebian runCommand:@"/sw/bin/dpkg-deb" withArguments:[NSArray arrayWithObjects: @"-x", pathToDebFile, folderPath , nil]];
    NSDictionary *dict = [shDebian parseControlFileWithPath:[folderPath stringByAppendingPathComponent:@"DEBIAN/control"]];
    NSLog(@"%@", dict);
    return @"";
}
+ (BOOL) uploadFileWithPath: (NSString *) filePath toPath: (NSString *) pathOnServer silent: (BOOL) silent
{
    NSString *destinationPath = [IPHONENERD_FTPROOT stringByAppendingString:pathOnServer];
    NSLog(@"from %@ \r\nto %@", filePath,destinationPath);
    if (silent) {
        return ([[shDebian runCommand:@"/usr/bin/curl" withArguments:[NSArray arrayWithObjects:@"-#",@"-T",filePath,destinationPath, nil]] isEqualToString:@""]);
    }else
    {
        shFTPPanel *ftpPanel = [[shFTPPanel alloc] initWithWindowNibName:@"shFTPPanel_Window"];
       return [ftpPanel uploadFileFromPath:filePath toPath:destinationPath];
    }
}
+ (BOOL) downloadFileWithPath: (NSString *) pathOnServer  toPath: (NSString *) filePath silent: (BOOL) silent
{
    NSString *sourcePath = [IPHONENERD_FTPROOT stringByAppendingString:pathOnServer];
    NSLog(@"from %@ \r\nto %@", filePath,sourcePath);
    if (silent) {
        return ([[shDebian runCommand:@"/usr/bin/curl" withArguments:[NSArray arrayWithObjects:@"-#",@"-o",filePath,sourcePath, nil]] isEqualToString:@""]);
    }else
    {
        shFTPPanel *ftpPanel = [[shFTPPanel alloc] initWithWindowNibName:@"shFTPPanel_Window"];
        return [ftpPanel downloadFileFromPath:sourcePath toPath:filePath];
    }
}
+ (BOOL) uploadDebPackageWithName: (NSString *) packageName silent: (BOOL) silent
{
    NSString *sourceFile = [[shDebian workingFolderWithSubfolder:SHDEBIAN_WORKINGFOLDER_REPODEB] stringByAppendingPathComponent:packageName];
    return [shDebian uploadFileWithPath:sourceFile toPath:[NSString stringWithFormat:@"cydia/debs/%@",packageName] silent:silent];
}
+ (void) prepareTools
{
	NSString *ns=[NSString stringWithContentsOfFile:@"/sw/bin/dpkg-scanpackages" encoding: NSUTF8StringEncoding error: NULL];
	ns = [ns stringByReplacingOccurrencesOfString:@"'MD5sum',\n            'Description'"  withString:@"'MD5sum', 'Name', 'Author', 'Homepage', 'Icon', 'Description'"];
	ns = [ns stringByReplacingOccurrencesOfString:@"'MD5sum', 'Description'"  withString:@"'MD5sum', 'Name', 'Author', 'Homepage', 'Icon', 'Description'"]; 
	
	//[testTXT setString:ns];
	[ns writeToFile: [[shDebian workingFolderWithSubfolder:SHDEBIAN_WORKINGFOLDER_ROOT] stringByAppendingPathComponent:@"dpkg-scanpackages"] atomically:YES encoding: NSUTF8StringEncoding error: NULL];
    
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/bin/bash"];
	[task setArguments:[NSArray arrayWithObjects:[[NSBundle mainBundle] pathForResource:@"cpScanPackages" ofType:@"sh"], nil]];
	[task launch];
}
+ (NSDictionary *) parseControlFileWithPath: (NSString *) filePath
{
    NSLog(@"control file with path: %@", filePath);
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	if([fileMgr fileExistsAtPath: filePath])
	{
        NSError *error;
        NSString *data = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error: &error];
        if(!data)
            data = [NSString stringWithContentsOfFile:filePath encoding:NSASCIIStringEncoding error: &error];
        if(!data)
        {
            NSAlert *theAlert = [[NSAlert alloc] init];
            [theAlert addButtonWithTitle:@"OK"];
            [theAlert setMessageText:@"Error in Control File"];
            [theAlert setInformativeText:@"Can't open the control file"];
            [theAlert setAlertStyle:0];
            [theAlert runModal];
            return nil;
        }
        //NSLog(@"control file contents: |||%@||| withError: %@", data,error);
		NSArray *lines = [data componentsSeparatedByString:@"\n"];
        for (NSString *line in lines) {
            NSString *lastKey = @"";
            if([line length] > 0)
            {
                if([line characterAtIndex:0] != ' ' && [line characterAtIndex:0] != '\t')
                {
                    @try
                    {
                        lastKey = [[line substringToIndex:[line rangeOfString:@":"].location] capitalizedString];
                        [dict setValue: [line substringFromIndex:[line rangeOfString:@":"].location+2] forKey:lastKey];
                    }
                    @catch (NSException *exception) {
                        NSLog(@"error parsing: %@",exception);
                        ;
                    }
                    @finally {
                        
                    }
                   
                }
                else
                {
                    [dict setValue:[[dict objectForKey:lastKey] stringByAppendingFormat:@"\n%@", line] forKey:lastKey];
                }
            }
        }
    }
    return dict;
}
+ (BOOL) writeControlFileWithData: (NSDictionary *) data toPath: (NSString *) filePath
{
    NSMutableString *result = [NSMutableString string];
    [data enumerateKeysAndObjectsUsingBlock:^(id key,id obj, BOOL *stop){
        [result appendFormat:@"%@: %@\n", key, obj]; 
    }];
    [result appendString:@"\n"];
    return [result writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}
+ (BOOL) createLocalPackagesListFileAndUpdateServer: (BOOL) shouldUpdate
{
    NSLog(@"%@",[shDebian workingFolderWithSubfolder:SHDEBIAN_WORKINGFOLDER_REPODEB]);

    NSString *packagesFilePath = [[shDebian workingFolderWithSubfolder:SHDEBIAN_WORKINGFOLDER_REPO] stringByAppendingPathComponent:@"Packages"];
    NSString *serverPackageFilePath = [[shDebian workingFolderWithSubfolder:SHDEBIAN_WORKINGFOLDER_OTHERFILES] stringByAppendingPathComponent: @"Packages"];
    [[NSFileManager defaultManager] removeItemAtPath:packagesFilePath error:NULL];
    [[NSFileManager defaultManager] removeItemAtPath:serverPackageFilePath error:NULL];
    
        [shDebian runCommand:@"/usr/bin/open" withArguments:[NSArray arrayWithObjects:[[NSBundle mainBundle] pathForResource:@"shScanPackages" ofType:@"app"], @"-W", nil]];
    if([[NSFileManager defaultManager] fileExistsAtPath:packagesFilePath]){
        [[NSFileManager defaultManager] removeItemAtPath:[shDebian workingFolderWithSubfolder:SHDEBIAN_WORKINGFOLDER_REPODEB] error:NULL];
        if (shouldUpdate) {
            
            if ([shDebian downloadFileWithPath: @"cydia/Packages" toPath:serverPackageFilePath silent:YES])
            {
                [shDebian processPackagesFile:packagesFilePath andMergeWithPackagesFile:serverPackageFilePath thenSaveItTo:packagesFilePath];
            }
        }
        [shDebian runCommand:@"/usr/bin/bzip2" withArguments:[NSArray arrayWithObjects:@"-fks",packagesFilePath, nil]];
        [shDebian uploadFileWithPath:packagesFilePath toPath:@"cydia/Packages" silent:YES];
        [shDebian uploadFileWithPath:[NSString stringWithFormat:@"%@.bz2", packagesFilePath] toPath:@"cydia/Packages.bz2" silent:YES];

    }else
    {
        NSAlert *theAlert = [[NSAlert alloc] init];
        [theAlert addButtonWithTitle:@"OK"];
        [theAlert setMessageText:@"Cannot Update Server!"];
        [theAlert setInformativeText:@"No Packages Found."];
        [theAlert setAlertStyle:0];
        [theAlert runModal];
    }
    return YES;
}
+ (void) processPackagesFile: (NSString *)file1 andMergeWithPackagesFile: (NSString*) file2 thenSaveItTo: (NSString *) destination
{
    NSString *localOne = [NSString stringWithContentsOfFile:file1 encoding:NSUTF8StringEncoding error:NULL];
    NSMutableString *serverOne = [NSMutableString stringWithContentsOfFile:file2 encoding:NSUTF8StringEncoding error:NULL];
    // check for updates
    NSArray * localPackages = [localOne componentsSeparatedByString:@"\n\n"];
    NSMutableArray * serverPackages = [[serverOne componentsSeparatedByString:@"\n\n"] mutableCopy];
    for(NSString *package in localPackages)
    {
        
        
        
        //if(range.location != NSNotFound)
        //{
            //NSLog(@"dupicate");
            // the package is a duplicate
            //NSRange rangeToDelete = NSMakeRange(range.location, [serverOne rangeOfString:@"\r\n" options:NSCaseInsensitiveSearch range:NSMakeRange(range.location, serverOne.length - range.location)].location);
            for(NSString *srvPackage in serverPackages)
            {
                if([srvPackage rangeOfString:[[package componentsSeparatedByString:@"\n"] objectAtIndex:0]].location != NSNotFound)
                {
                    [serverPackages removeObject:srvPackage];
                    break;
                }
            //[serverOne deleteCharactersInRange:rangeToDelete];
            }
        //}
    }
    //
    [serverPackages addObjectsFromArray:localPackages];
    //[serverOne appendString:localOne];
    NSLog(@"saving");
    [[serverPackages componentsJoinedByString:@"\n\n"] writeToFile:destination atomically:NO encoding:NSUTF8StringEncoding error:NULL];
    //[serverOne writeToFile:destination atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}
+ (NSMutableArray *) parsePackagesFile: (NSString *)file
{
    NSError *error;
    NSString *localOne = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:&error];
    if(error)
        localOne = [NSString stringWithContentsOfFile:file encoding:NSASCIIStringEncoding error:&error];
    // check for updates
    NSArray * localPackages = [localOne componentsSeparatedByString:@"\n\n"];
    if([localPackages count] < [[localOne componentsSeparatedByString:@"\r\n\r\n"] count])
       localPackages = [localOne componentsSeparatedByString:@"\r\n\r\n"];
    NSMutableArray *files = [NSMutableArray array];
    NSLog(@"packages: %lu", [localPackages count]);
    for(NSString *package in localPackages)
    {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        NSArray *lines = [package componentsSeparatedByString:@"\n"];
        for (NSString *line in lines) {
            NSString *lastKey = @"";
            if([line length] > 0)
            {
                if([line characterAtIndex:0] != ' ' && [line characterAtIndex:0] != '\t')
                {
                    @try
                    {
                        lastKey = [[line substringToIndex:[line rangeOfString:@":"].location] capitalizedString];
                        [dict setValue: [line substringFromIndex:[line rangeOfString:@":"].location+2] forKey:lastKey];
                    }
                    @catch (NSException *exception) {
                        NSLog(@"error parsing: %@",exception);
                        ;
                    }
                    @finally {
                        
                    }
                    
                }
                else
                {
                    [dict setValue:[[dict objectForKey:lastKey] stringByAppendingFormat:@"\n%@", line] forKey:lastKey];
                }
            }
        }
        [dict setObject:[file lastPathComponent] forKey:@"shSourceRepo"];
        [files addObject:dict];
    }
    
    return files;
}
@end
