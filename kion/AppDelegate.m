//
//  AppDelegate.m
//  kion
//
//  Created by Mario C. Delgado Jr. on 3/29/15.
//  Copyright (c) 2015 Mario C. Delgado Jr. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property NSString *loc;
@property NSString *cond;


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *appGroupContainer = [fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.com.mycompany.myapp"];
    if (!appGroupContainer) {
        NSLog(@"group identifier incorrect, or app groups not setup correctly");
    }    return YES;
    
    if (application.applicationState != UIApplicationStateBackground) {
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"myStoryboardName" bundle:nil];
        self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"myRootController"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleReachabilityChange:)
                                                     name:@"conditions"
                                                   object:nil];
    }

    
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSCalendarOptions options = NSCalendarMatchNextTime;
    NSDate *nextNineThirty = [calendar nextDateAfterDate:[NSDate date]
                                            matchingHour:16
                                                  minute:30
                                                  second:30
                                                 options:options];
    
    
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = nextNineThirty;
    localNotification.alertBody = @"It will be %@ tomrorow", self.cond;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.repeatInterval = NSCalendarUnitDay;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)handleReachabilityChange:(NSNotification *)note {
    NSDictionary *theData = [note userInfo];
    if (theData != nil) {
        _loc = [theData objectForKey:@"location"];
        _cond = [theData objectForKey:@"condition"];

    }
}


- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply
{
        NSString * request = [userInfo objectForKey:@"requestString"];
    // Temporary fix, I hope.
    // --------------------
    __block UIBackgroundTaskIdentifier bogusWorkaroundTask;
    bogusWorkaroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bogusWorkaroundTask];
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] endBackgroundTask:bogusWorkaroundTask];
    });
    // --------------------
    
    __block UIBackgroundTaskIdentifier realBackgroundTask;
    realBackgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        reply(nil);
        [[UIApplication sharedApplication] endBackgroundTask:realBackgroundTask];
    }];
    
    [self handleReachabilityChange:nil];
    
    NSArray * objects = [[NSArray alloc] initWithObjects: @"%@", _loc, @"%@", _cond, nil];
    
    NSArray * keys = [[NSArray alloc] initWithObjects:@"location1", @"cond", nil];
    NSDictionary * replyContent = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
   
    reply(replyContent);
    
    
    [[UIApplication sharedApplication] endBackgroundTask:realBackgroundTask];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
