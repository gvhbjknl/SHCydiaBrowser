//
//  shFTPPanel.h
//  shRepoManager
//
//  Created by Shahin Katebi on 12/8/90.
//  Copyright (c) 1390 Idea Pardazan Seeb Co. LTD. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
@protocol shFTPPanelDelegate
@optional
- (void) operationCompleted: (id)result;
@end
@interface shFTPPanel : NSWindowController
- (BOOL) uploadFileFromPath: (NSString *) sourcePath toPath: (NSString *) destinationPath;
- (BOOL) downloadFileFromPath: (NSString *) sourcePath toPath: (NSString *) destinationPath;
@end

