//
//  NSData+Bzip2.h
//  CydiaNerd
//
//  Created by Shahin Katebi on 12/26/90.
//  Copyright (c) 1390 Idea Pardazan Seeb Co. LTD. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Bzip2)
- (NSData *) bzip2WithCompressionSetting:(int)OneToNine;
- (NSData *) bunzip2;
@end
