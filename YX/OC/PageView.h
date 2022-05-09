//
//  PageView.h
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "TapResult.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PageUpdater <NSObject>
- (void)update;
@end

@protocol PageView <PageUpdater>

- (int)number;
- (void)willRotate;
- (void)showLinks;
- (void)hideLinks;
- (void)showSearchResults:(int)count;
- (void)clearSearchResults;
- (void)resetZoomAnimated:(BOOL)animated;
- (void)setScale:(float)scale;
- (TapResult *)handleTap:(CGPoint)pt;
- (void)textSelectModeOn;
- (void)textSelectModeOff;
- (void)deselectAnnotation;
- (void)deleteSelectedAnnotation;
- (void)inkModeOn;
- (void)inkModeOff;
- (void)saveSelectionAsMarkup:(int)type;
- (void)saveInk;
- (void)update;

@end

NS_ASSUME_NONNULL_END
