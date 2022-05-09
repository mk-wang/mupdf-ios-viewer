//
//  PDFWord.h
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDFWord : NSObject

@property (nonatomic, assign, readonly) CGRect rect;

+ (void)selectFrom:(CGPoint)pt1
                to:(CGPoint)pt2
         fromWords:(NSArray<NSArray<PDFWord *> *> *)words
       onStartLine:(nullable void (^)(void))startBlock
            onWord:(nullable void (^)(PDFWord *))wordBlock
         onEndLine:(nullable void (^)(void))endBLock;

- (void)appendChar:(unichar)c withRect:(CGRect)rect;

- (NSString *)text;

@end

NS_ASSUME_NONNULL_END
