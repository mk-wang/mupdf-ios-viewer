#import <UIKit/UIKit.h>

#undef ABS
#undef MIN
#undef MAX

#import "MuDocRef.h"

@interface MuLibraryController : UITableViewController <UIActionSheetDelegate>
- (void) openDocument: (NSString*)filename;
- (void) askForPassword: (NSString*)prompt;
- (void) onPasswordOkay;
- (void) onPasswordCancel;
- (void) reload;
@end
