//
//  PDFDoc.h
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDFDoc : NSObject

@property (nullable, nonatomic, copy) NSString *path;

@property (nullable, nonatomic, copy) NSString *name;

@property (nonatomic, assign) BOOL interactive;

@property (nonatomic, assign) BOOL isOpen;

- (instancetype)initWithPath:(NSString *)path;

- (void)open;
- (void)close;

- (BOOL)needPassword;
- (BOOL)authPassword:(NSString *)password;

@end

NS_ASSUME_NONNULL_END
