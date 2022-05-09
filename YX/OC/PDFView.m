//
//  PDFView.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFView.h"

@implementation PDFView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)update {
    <#code#>
}

- (void)clearSearchResults {
    <#code#>
}

- (void)deleteSelectedAnnotation {
    <#code#>
}

- (void)deselectAnnotation {
    <#code#>
}

- (nonnull TapResult *)handleTap:(CGPoint)pt {
    <#code#>
}

- (void)hideLinks {
    <#code#>
}

- (void)inkModeOff {
    <#code#>
}

- (void)inkModeOn {
    <#code#>
}

- (int)number {
    <#code#>
}

- (void)resetZoomAnimated:(BOOL)animated {
    <#code#>
}

- (void)saveInk {
    <#code#>
}

- (void)saveSelectionAsMarkup:(int)type {
    <#code#>
}

- (void)setScale:(float)scale {
    <#code#>
}

- (void)showLinks {
    <#code#>
}

- (void)showSearchResults:(int)count {
    <#code#>
}

- (void)textSelectModeOff {
    <#code#>
}

- (void)textSelectModeOn {
    <#code#>
}

- (void)willRotate {
    <#code#>
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    <#code#>
}

+ (nonnull instancetype)appearance {
    <#code#>
}

+ (nonnull instancetype)appearanceForTraitCollection:(nonnull UITraitCollection *)trait {
    <#code#>
}

+ (nonnull instancetype)appearanceForTraitCollection:(nonnull UITraitCollection *)trait whenContainedIn:(nullable Class<UIAppearanceContainer>)ContainerClass, ... {
    <#code#>
}

+ (nonnull instancetype)appearanceForTraitCollection:(nonnull UITraitCollection *)trait whenContainedInInstancesOfClasses:(nonnull NSArray<Class<UIAppearanceContainer>> *)containerTypes {
    <#code#>
}

+ (nonnull instancetype)appearanceWhenContainedIn:(nullable Class<UIAppearanceContainer>)ContainerClass, ... {
    <#code#>
}

+ (nonnull instancetype)appearanceWhenContainedInInstancesOfClasses:(nonnull NSArray<Class<UIAppearanceContainer>> *)containerTypes {
    <#code#>
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    <#code#>
}

- (CGPoint)convertPoint:(CGPoint)point fromCoordinateSpace:(nonnull id<UICoordinateSpace>)coordinateSpace {
    <#code#>
}

- (CGPoint)convertPoint:(CGPoint)point toCoordinateSpace:(nonnull id<UICoordinateSpace>)coordinateSpace {
    <#code#>
}

- (CGRect)convertRect:(CGRect)rect fromCoordinateSpace:(nonnull id<UICoordinateSpace>)coordinateSpace {
    <#code#>
}

- (CGRect)convertRect:(CGRect)rect toCoordinateSpace:(nonnull id<UICoordinateSpace>)coordinateSpace {
    <#code#>
}

- (void)didUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context withAnimationCoordinator:(nonnull UIFocusAnimationCoordinator *)coordinator {
    <#code#>
}

- (void)setNeedsFocusUpdate {
    <#code#>
}

- (BOOL)shouldUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context {
    <#code#>
}

- (void)updateFocusIfNeeded {
    <#code#>
}

- (nonnull NSArray<id<UIFocusItem>> *)focusItemsInRect:(CGRect)rect {
    <#code#>
}

@end
