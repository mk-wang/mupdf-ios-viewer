//
//  PDFLink.h
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDFLink : NSObject

@property (nullable, nonatomic, copy, readonly) NSString *url;
@property (nonatomic, assign, readonly) NSInteger number;
@property (nonatomic, assign, readonly) CGRect rect;

+ (NSArray<PDFLink *> *)linksFromHeader:(void *)header;

- (instancetype)initWithLink:(void *)link;

@end

NS_ASSUME_NONNULL_END
