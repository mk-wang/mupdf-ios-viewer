#import <Foundation/Foundation.h>

#import "PDFAnnotation.h"

@class TapResultInternalLink;
@class TapResultExternalLink;
@class TapResultRemoteLink;
@class TapResultWidget;
@class TapResultAnnotation;

@interface TapResult : NSObject

- (void)switchCaseInternal:(void (^)(TapResultInternalLink *))internalLinkBlock
              caseExternal:(void (^)(TapResultExternalLink *))externalLinkBlock
                caseRemote:(void (^)(TapResultRemoteLink *))remoteLinkBlock
                caseWidget:(void (^)(TapResultWidget *))widgetBlock
            caseAnnotation:(void (^)(TapResultAnnotation *))annotationBlock;
@end

@interface TapResultInternalLink : TapResult

@property (nonatomic, assign, readonly) int pageNumber;

- (instancetype)initWithPageNumber:(int)aNumber;

@end

@interface TapResultExternalLink : TapResult

@property (nonatomic, copy, readonly) NSString *urlStr;

- (instancetype)initWithUrl:(NSString *)aString;

@end

@interface TapResultRemoteLink : TapResult

@property (nonatomic, copy, readonly) NSString *fileSpec;
@property (nonatomic, assign, readonly) int pageNumber;
@property (nonatomic, assign, readonly) BOOL newWindow;

- (instancetype)initWithFileSpec:(NSString *)aString
                      pageNumber:(int)aNumber
                       newWindow:(BOOL)aBool;
@end

@interface TapResultWidget : TapResult
@end

@interface TapResultAnnotation : TapResult

@property (nonatomic, strong, readonly) PDFAnnotation *annot;

- (instancetype)initWithAnnotation:(PDFAnnotation *)aAnnot;

@end
