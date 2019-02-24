//
//  shFileStream.h
//  CydiaNerd
//
//  Created by Shahin Katebi on 12/28/90.
//  Copyright (c) 1390 Idea Pardazan Seeb Co. LTD. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define SHFILESTREAM_OPERATION_HTTPDOWNLOAD @"httpdownload"
#define SHFILESTREAM_OPERATION_HTTPUPLOAD @"httpupload"

#define SHFILESTREAM_RESULT_FINISHED @"finished"
#define SHFILESTREAM_RESULT_CANCELED @"canceled"
@class shFileStream;
@protocol shFileStreamDelegate <NSObject>
- (void) fileStream: (shFileStream *) fileStream  operationDidFinishedWithResult: (NSString *) result;
@end
@interface shFileStream : NSWindowController
@property (nonatomic, strong) NSString *operation;
@property (nonatomic, strong) NSArray *parameters;
@property (nonatomic, strong) id<shFileStreamDelegate> delegate;

- (id) initWithOperationType: (NSString *) type andParameters: (NSArray *) params;
-(void) executeActionWithWindow: (NSWindow *) window;
@end
