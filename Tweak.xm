#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <dispatch/dispatch.h>
#import <QuartzCore/QuartzCore.h>

// Keep this tweak intentionally narrow: block Shopee's app scheme and its
// short-link host, while allowing all unrelated URLs through unchanged.
static BOOL SBShouldBlockURL(NSURL *url) {
    if (![url isKindOfClass:[NSURL class]]) return NO;
    NSString *scheme = url.scheme.lowercaseString ?: @"";
    NSString *host = url.host.lowercaseString ?: @"";
    return [scheme isEqualToString:@"shopeevn"] || [host isEqualToString:@"s.shopee.vn"];
}

// Correlate a blocked Shopee URL with the FBStackViewController ->
// FBStackViewController presentation observed during testing. Consume once.
// This does not hook or modify FacebookPlus.
static CFTimeInterval SBLastBlockedShopeeTime = 0;
static BOOL SBPendingIABPresentationBlock = NO;
static const CFTimeInterval SBPresentationCorrelationWindow = 1.0;

static void SBMarkBlockedShopeeURL(void) {
    @synchronized ([NSObject class]) {
        SBLastBlockedShopeeTime = CACurrentMediaTime();
        SBPendingIABPresentationBlock = YES;
    }
}

static BOOL SBConsumeCorrelatedIABPresentation(UIViewController *presenter,
                                               UIViewController *presented) {
    NSString *presenterClass = presenter ? NSStringFromClass([presenter class]) : @"";
    NSString *presentedClass = presented ? NSStringFromClass([presented class]) : @"";
    BOOL validPresenter =
        [presenterClass isEqualToString:@"FBStackViewController"] ||
        [presenterClass isEqualToString:@"FBTopBarAndContentViewController"];

    if (!validPresenter ||
        ![presentedClass isEqualToString:@"FBStackViewController"]) {
        return NO;
    }

    @synchronized ([NSObject class]) {
        CFTimeInterval age = CACurrentMediaTime() - SBLastBlockedShopeeTime;
        if (!SBPendingIABPresentationBlock || age < 0 || age > SBPresentationCorrelationWindow) {
            return NO;
        }
        SBPendingIABPresentationBlock = NO;
        return YES;
    }
}

static BOOL (*SBOrigOpenURLLegacy)(UIApplication *, SEL, NSURL *);
static void (*SBOrigOpenURLWithOptions)(UIApplication *, SEL, NSURL *, NSDictionary *, void (^)(BOOL));

static BOOL SBHookOpenURLLegacy(UIApplication *application, SEL selector, NSURL *url) {
    BOOL block = SBShouldBlockURL(url);
    if (block) {
        SBMarkBlockedShopeeURL();
        return NO;
    }
    return SBOrigOpenURLLegacy ? SBOrigOpenURLLegacy(application, selector, url) : NO;
}

static void SBHookOpenURLWithOptions(UIApplication *application, SEL selector, NSURL *url,
                                     NSDictionary *options, void (^completionHandler)(BOOL)) {
    BOOL block = SBShouldBlockURL(url);
    if (block) {
        SBMarkBlockedShopeeURL();
        // Report the deep link as handled to reduce Facebook's HTTPS fallback.
        if (completionHandler) {
            void (^handlerCopy)(BOOL) = [completionHandler copy];
            dispatch_async(dispatch_get_main_queue(), ^{
                handlerCopy(YES);
            });
        }
        return;
    }

    if (SBOrigOpenURLWithOptions) {
        SBOrigOpenURLWithOptions(application, selector, url, options, completionHandler);
    } else if (completionHandler) {
        completionHandler(NO);
    }
}

static void (*SBOrigPresent)(UIViewController *, SEL, UIViewController *, BOOL, void (^)(void));
static void SBHookPresent(UIViewController *self, SEL selector, UIViewController *viewController,
                          BOOL animated, void (^completion)(void)) {
    BOOL correlated = SBConsumeCorrelatedIABPresentation(self, viewController);
    if (correlated) {
        if (completion) dispatch_async(dispatch_get_main_queue(), completion);
        return;
    }
    if (SBOrigPresent) SBOrigPresent(self, selector, viewController, animated, completion);
}

static void SBInstallHook(Class cls, SEL selector, IMP replacement, IMP *original) {
    if (!cls || !class_getInstanceMethod(cls, selector)) return;
    MSHookMessageEx(cls, selector, replacement, original);
}

__attribute__((constructor))
static void InitShopeeBlocker(void) {
    @autoreleasepool {
        Class applicationClass = objc_getClass("UIApplication");
        SBInstallHook(applicationClass, @selector(openURL:options:completionHandler:),
                      (IMP)SBHookOpenURLWithOptions, (IMP *)&SBOrigOpenURLWithOptions);
        SBInstallHook(applicationClass, @selector(openURL:),
                      (IMP)SBHookOpenURLLegacy, (IMP *)&SBOrigOpenURLLegacy);
        SBInstallHook(objc_getClass("UIViewController"),
                      @selector(presentViewController:animated:completion:),
                      (IMP)SBHookPresent, (IMP *)&SBOrigPresent);
    }
}
