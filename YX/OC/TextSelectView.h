//
//  TextSelectView.h
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TextSelectView : UIView

@property (nonatomic, readonly) NSArray *selectionRects;
@property (nonatomic, readonly) NSString *selectedText;

- (instancetype)initWithWords:(NSArray *)words
                     pageSize:(CGSize)pageSize;

@end

NS_ASSUME_NONNULL_END
