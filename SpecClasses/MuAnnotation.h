#import <Foundation/Foundation.h>

//struct fz_annot;

@interface MuAnnotation : NSObject
-(instancetype) initFromAnnot:(void *)annot;
@property(readonly) int type;
@property(readonly) CGRect rect;
+(MuAnnotation *) annotFromAnnot:(void *)annot;
@end
