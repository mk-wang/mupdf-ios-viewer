#import <UIKit/UIKit.h>
#import "MuTapResult.h"

#undef ABS
#undef MIN
#undef MAX

@interface MuHitView : UIView
- (instancetype) initWithSearchResults: (int)n forDocument: (void *)doc;
- (instancetype) initWithLinks: (void*)links forDocument: (void *)doc;
- (void) setPageSize: (CGSize)s;
- (MuTapResult *) handleTap:(CGPoint)pt;
@end
