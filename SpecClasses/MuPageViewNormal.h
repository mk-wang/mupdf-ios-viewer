#import <UIKit/UIKit.h>

#undef ABS
#undef MIN
#undef MAX

#import "MuAnnotSelectView.h"
#import "MuDialogCreator.h"
#import "MuDocRef.h"
#import "MuHitView.h"
#import "MuInkView.h"
#import "MuPageView.h"
#import "MuTextSelectView.h"
#import "MuUpdater.h"

@interface MuPageViewNormal : UIScrollView <UIScrollViewDelegate, MuPageView>
- (instancetype)initWithFrame:(CGRect)frame
                dialogCreator:(id<MuDialogCreator>)dia
                      updater:(id<MuUpdater>)upd
                     document:(MuDocRef *)aDoc
                         page:(int)aNumber;
- (void)displayImage:(UIImage *)image;
- (void)resizeImage;
- (void)loadPage;
- (void)loadTile;
@end
