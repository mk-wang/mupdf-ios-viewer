//
//  PDFUtils+Create.h
//  MuPDF
//
//  Created by MK on 2022/5/20.
//

#import <Foundation/Foundation.h>
#import "PDFUtils.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^PDFCreateProgress)(NSInteger current, NSInteger total, NSString * _Nullable info);

@interface PDFUtils (Create)

+ (BOOL)setPassword:(NSURL*)source
               dest:(NSURL *)dest
           password:(NSString *)password
              crypt:(BOOL)crypt
           progress:(PDFCreateProgress)progress;

@end

NS_ASSUME_NONNULL_END
