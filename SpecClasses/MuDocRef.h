#import <Foundation/Foundation.h>

@interface MuDocRef : NSObject {
@public
    void *doc;
    bool interactive;
}
- (instancetype)initWithFilename:(NSString *)aFilename;
@end
