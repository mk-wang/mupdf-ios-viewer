#import "MuTapResult.h"
#import <UIKit/UIKit.h>

@protocol MuPageView
@property (NS_NONATOMIC_IOSONLY, readonly) int number;
- (void)willRotate;
- (void)showLinks;
- (void)hideLinks;
- (void)showSearchResults:(int)count;
- (void)clearSearchResults;
- (void)resetZoomAnimated:(BOOL)animated;
- (void)setScale:(float)scale;
- (MuTapResult *)handleTap:(CGPoint)pt;
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
