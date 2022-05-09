//
//  PDFWord.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFWord.h"

@implementation PDFWord {
    NSMutableString *_mString;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mString = [NSMutableString new];
    }
    return self;
}

- (NSString *)text
{
    return [_mString description];
}

- (void)appendChar:(unichar)c withRect:(CGRect)rect
{
    [_mString appendFormat:@"%C", c];
    _rect = CGRectUnion(_rect, rect);
}

+ (void)selectFrom:(CGPoint)pt1
                to:(CGPoint)pt2
         fromWords:(NSArray<NSArray<PDFWord *> *> *)words
       onStartLine:(nullable void (^)(void))startBlock
            onWord:(nullable void (^)(PDFWord *))wordBlock
         onEndLine:(nullable void (^)(void))endBLock
{
    CGPoint toppt, botpt;
    if (pt1.y < pt2.y) {
        toppt = pt1;
        botpt = pt2;
    } else {
        toppt = pt2;
        botpt = pt1;
    }

    for (NSArray *line in words) {
        PDFWord *fst = line[0];
        float ltop = fst.rect.origin.y;
        float lbot = ltop + fst.rect.size.height;

        if (toppt.y < lbot && ltop < botpt.y) {
            BOOL topline = toppt.y > ltop;
            BOOL botline = botpt.y < lbot;
            float left = -INFINITY;
            float right = INFINITY;

            if (topline && botline) {
                left = MIN(toppt.x, botpt.x);
                right = MAX(toppt.x, botpt.x);
            } else if (topline) {
                left = toppt.x;
            } else if (botline) {
                right = botpt.x;
            }

            if (startBlock != nil) {
                startBlock();
            }

            if (wordBlock != nil) {
                for (PDFWord *word in line) {
                    float wleft = word.rect.origin.x;
                    float wright = wleft + word.rect.size.width;

                    if (wright > left && wleft < right) {
                        wordBlock(word);
                    }
                }
            }

            if (endBLock != nil) {
                endBLock();
            }
        }
    }
}
@end
