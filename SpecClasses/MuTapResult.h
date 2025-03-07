#import "MuAnnotation.h"
#import <Foundation/Foundation.h>

@class MuTapResultInternalLink;
@class MuTapResultExternalLink;
@class MuTapResultRemoteLink;
@class MuTapResultWidget;
@class MuTapResultAnnotation;

@interface MuTapResult : NSObject
- (void)
    switchCaseInternal:(void (^)(MuTapResultInternalLink *))internalLinkBlock
          caseExternal:(void (^)(MuTapResultExternalLink *))externalLinkBlock
            caseRemote:(void (^)(MuTapResultRemoteLink *))remoteLinkBlock
            caseWidget:(void (^)(MuTapResultWidget *))widgetBlock
        caseAnnotation:(void (^)(MuTapResultAnnotation *))annotationBlock;
@end

@interface MuTapResultInternalLink : MuTapResult
@property (readonly) int pageNumber;
- (instancetype)initWithPageNumber:(int)aNumber;
@end

@interface MuTapResultExternalLink : MuTapResult
@property (readonly) NSString *url;
- (instancetype)initWithUrl:(NSString *)aString;
@end

@interface MuTapResultRemoteLink : MuTapResult
@property (readonly) NSString *fileSpec;
@property (readonly) int pageNumber;
@property (readonly) BOOL newWindow;
- (instancetype)initWithFileSpec:(NSString *)aString
                      pageNumber:(int)aNumber
                       newWindow:(BOOL)aBool;
@end

@interface MuTapResultWidget : MuTapResult
@end

@interface MuTapResultAnnotation : MuTapResult
@property (readonly) MuAnnotation *annot;
- (instancetype)initWithAnnotation:(MuAnnotation *)aAnnot;
@end
