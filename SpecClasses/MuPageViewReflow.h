#import "MuDocRef.h"
#import "MuPageView.h"
#import <UIKit/UIKit.h>

@interface MuPageViewReflow : UIWebView <UIWebViewDelegate, MuPageView>

- (instancetype)initWithFrame:(CGRect)frame
                     document:(MuDocRef *)aDoc
                         page:(int)aNumber;

@end
