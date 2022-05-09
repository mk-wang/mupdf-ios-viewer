//
//  HighLightView.h
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HighLightView : UIView

@property (nonatomic, strong) UIColor *highlightColor;
@property (nonatomic, copy) NSArray<NSValue *> *rectList;

@property (nonatomic, assign) CGSize pageSize;

- (instancetype)initWithFrame:(CGRect)rect
                     rectList:(NSArray *)list
               highlightColor:(UIColor *)color;
@end

NS_ASSUME_NONNULL_END
