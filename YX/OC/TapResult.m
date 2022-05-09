#import "TapResult.h"

@implementation TapResult

- (void)switchCaseInternal:(void (^)(TapResultInternalLink *))internalLinkBlock
              caseExternal:(void (^)(TapResultExternalLink *))externalLinkBlock
                caseRemote:(void (^)(TapResultRemoteLink *))remoteLinkBlock
                caseWidget:(void (^)(TapResultWidget *))widgetBlock
            caseAnnotation:(void (^)(TapResultAnnotation *))annotationBlock
{
}

@end

@implementation TapResultInternalLink

- (instancetype)initWithPageNumber:(int)aNumber
{
    self = [super init];
    if (self) {
        _pageNumber = aNumber;
    }
    return self;
}

- (void)switchCaseInternal:(void (^)(TapResultInternalLink *))internalLinkBlock
              caseExternal:(void (^)(TapResultExternalLink *))externalLinkBlock
                caseRemote:(void (^)(TapResultRemoteLink *))remoteLinkBlock
                caseWidget:(void (^)(TapResultWidget *))widgetBlock
            caseAnnotation:(void (^)(TapResultAnnotation *))annotationBlock
{
    internalLinkBlock(self);
}

@end

@implementation TapResultExternalLink

- (instancetype)initWithUrl:(NSString *)aString
{
    self = [super init];
    if (self) {
        _urlStr = aString.copy;
    }
    return self;
}

- (void)switchCaseInternal:(void (^)(TapResultInternalLink *))internalLinkBlock
              caseExternal:(void (^)(TapResultExternalLink *))externalLinkBlock
                caseRemote:(void (^)(TapResultRemoteLink *))remoteLinkBlock
                caseWidget:(void (^)(TapResultWidget *))widgetBlock
            caseAnnotation:(void (^)(TapResultAnnotation *))annotationBlock
{
    externalLinkBlock(self);
}

@end

@implementation TapResultRemoteLink

- (instancetype)initWithFileSpec:(NSString *)aString
                      pageNumber:(int)aNumber
                       newWindow:(BOOL)aBool
{
    self = [super init];
    if (self) {
        _fileSpec = [aString copy];
        _pageNumber = aNumber;
        _newWindow = aBool;
    }
    return self;
}

- (void)switchCaseInternal:(void (^)(TapResultInternalLink *))internalLinkBlock
              caseExternal:(void (^)(TapResultExternalLink *))externalLinkBlock
                caseRemote:(void (^)(TapResultRemoteLink *))remoteLinkBlock
                caseWidget:(void (^)(TapResultWidget *))widgetBlock
            caseAnnotation:(void (^)(TapResultAnnotation *))annotationBlock
{
    remoteLinkBlock(self);
}

@end

@implementation TapResultWidget

- (void)switchCaseInternal:(void (^)(TapResultInternalLink *))internalLinkBlock
              caseExternal:(void (^)(TapResultExternalLink *))externalLinkBlock
                caseRemote:(void (^)(TapResultRemoteLink *))remoteLinkBlock
                caseWidget:(void (^)(TapResultWidget *))widgetBlock
            caseAnnotation:(void (^)(TapResultAnnotation *))annotationBlock
{
    widgetBlock(self);
}

@end

@implementation TapResultAnnotation

- (instancetype)initWithAnnotation:(PDFAnnotation *)aAnnot
{
    self = [super init];
    if (self) {
        _annot = aAnnot;
    }
    return self;
}

- (void)switchCaseInternal:(void (^)(TapResultInternalLink *))internalLinkBlock
              caseExternal:(void (^)(TapResultExternalLink *))externalLinkBlock
                caseRemote:(void (^)(TapResultRemoteLink *))remoteLinkBlock
                caseWidget:(void (^)(TapResultWidget *))widgetBlock
            caseAnnotation:(void (^)(TapResultAnnotation *))annotationBlock
{
    annotationBlock(self);
}

@end
