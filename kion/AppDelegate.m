//
//  AppDelegate.m
//  kion
//
//  Created by Mario C. Delgado Jr. on 3/29/15.
//  Copyright (c) 2015 Mario C. Delgado Jr. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "KFOpenWeatherMapAPIClient.h"
#import "KFOWMWeatherResponseModel.h"
#import "KFOWMMainWeatherModel.h"
#import "KFOWMWeatherModel.h"
#import "KFOWMForecastResponseModel.h"
#import "KFOWMCityModel.h"
#import "KFOWMDailyForecastResponseModel.h"
#import "KFOWMDailyForecastListModel.h"
#import "KFOWMSearchResponseModel.h"
#import "KFOWMSystemModel.h"

CLLocationManager *locationManager;
CLGeocoder *geocoder;
int locationFetchCounter;
int refreshcounter;

@interface AppDelegate ()
@property NSString *loc;
@property NSString *cond;

@property (nonatomic, readwrite) CLLocationCoordinate2D mycord;
@property (nonatomic, readwrite) CLLocationDegrees lat;
@property (nonatomic, readwrite) CLLocationDegrees lon;
@property NSDictionary *result;
@property (nonatomic, strong) KFOpenWeatherMapAPIClient *apiClient;
@property (nonatomic, weak) NSString *condi;
@property (nonatomic, weak) NSDate *sunrise;
@property (nonatomic, weak) NSDate *sunset;
@property (nonatomic, weak) NSDate *time;


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    
    UIUserNotificationType notificationTypes = UIUserNotificationTypeBadge |
    UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    
    UIUserNotificationSettings *notificationsRegisterSettings =
    [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
    
    [application registerUserNotificationSettings:notificationsRegisterSettings];
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    return YES;
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
        NSString *request = [userInfo objectForKey:@"requestString"];
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
    

    
    NSArray * objects = [[NSArray alloc] initWithObjects: @"%@", _loc, @"%@", _cond, nil];
    
    NSArray * keys = [[NSArray alloc] initWithObjects:@"location1", @"cond", nil];
    NSDictionary * replyContent = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
   
    reply(replyContent);
    
    
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

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    
    
    
    
    locationManager = [[CLLocationManager alloc] init];
//    [locationManager requestWhenInUseAuthorization];
    //locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    geocoder = [[CLGeocoder alloc] init];
    
    locationFetchCounter = 0;
    
    // fetching current location start from here
    [locationManager startUpdatingLocation];

    
    NSLog(@"Background fetch...");
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    localNotification.alertBody = self.condi;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    completionHandler(UIBackgroundFetchResultNewData);
    

    
    
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    
    UIApplicationState state = [application applicationState];
    if (state == UIApplicationStateActive) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New local notification"
                                                        message:notification.alertBody
                                                       delegate:self cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    // this delegate method is constantly invoked every some miliseconds.
    // we only need to receive the first response, so we skip the others.
    if (locationFetchCounter > 0) return;
    locationFetchCounter++;
    
    // after we have current coordinates, we use this method to fetch the information data of fetched coordinate
    [geocoder reverseGeocodeLocation:[locations lastObject] completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = [placemarks lastObject];
        
        NSString *street = placemark.thoroughfare;
        NSString *city = placemark.locality;
        NSString *posCode = placemark.postalCode;
        NSString *country = placemark.country;
        
        NSLog(@"we live in %@", country);
        
        // stopping locationManager from fetching again
        [locationManager stopUpdatingLocation];
        
        
        
        
        self.apiClient = [[KFOpenWeatherMapAPIClient alloc] initWithAPIKey:@"810da70aaecb6564a2d192bdd4bc35e4" andAPIVersion:@"2.5"];
        
        
        [self.apiClient weatherForCityName:city withResultBlock:^(BOOL success, id responseData, NSError *error)
         {
             if (success)
             {
                 KFOWMWeatherResponseModel *responseModel = (KFOWMWeatherResponseModel *)responseData;
                 NSLog(@"received weather: %@, conditions: %@", responseModel.cityName, [responseModel valueForKeyPath:@"weather.main"][0]);
                 
                 
                 self.sunrise =  responseModel.systemInfo.sunrise;
                 NSLog(@"received weather: %@, sunrise: %@, current time: %@", responseModel.cityName, responseModel.systemInfo.sunrise, responseModel.dt);
                 self.sunset =  responseModel.systemInfo.sunset;
                 self.time = responseModel.dt;
                 
                 
                 
                 NSString *loc2 = [NSString stringWithFormat:@"%@", [responseModel valueForKeyPath:@"weather.main"][0]];
                 NSString *upper2 = [loc2 uppercaseString];
                 
                 //  self.weatherCond.text= [NSString stringWithFormat:@"It will be %@ tomorrow", upper2];
                 
                 NSLog(@"It's %@", upper2);
                 
                 NSString *loc1 = [NSString stringWithFormat:@"%@", responseModel.cityName];
                 NSString *upper1 = [loc1 uppercaseString];
            //     self.Location.text = upper1;
                 NSLog(@"It's %@", upper1);
                 
                 
             }}];
        
        [self.apiClient forecastForCityName:@"Los Angeles" withResultBlock:^(BOOL success, id responseData, NSError *error)
         {
             if (success)
             {
                 KFOWMForecastResponseModel *responseModel = (KFOWMForecastResponseModel *)responseData;
                 
                 NSString *forecast = [NSString stringWithFormat:@"%@", [responseModel.list valueForKeyPath:@"weather.main"][5][0]];
                 //              NSString *forecast = [forecast1 uppercaseString];
                 if ([forecast isEqualToString:@"Clear"])
                 {
                     forecast = [forecast stringByReplacingOccurrencesOfString:@"Clear"
                                                                    withString:@"nice"];
                 }
                 if ([forecast isEqualToString:@"Clouds"])
                 {
                     forecast = [forecast stringByReplacingOccurrencesOfString:@"Clouds"
                                                                    withString:@"cloudy"];
                 }
                 
                 
                 [forecast stringByReplacingOccurrencesOfString:@"Clouds"
                                                     withString:@"cloudy"];
                 
                 NSLog(@"It's %@", [responseModel.list valueForKeyPath:@"mainWeather.temperature"]);
                 
                 NSLog(@"It's %@", [responseModel.list valueForKeyPath:@"weather.main"]);
               //  self.weatherCond.text= [NSString stringWithFormat:@"It will probably be %@ later.", forecast];
                 self.condi = [NSString stringWithFormat:@"It will probably be %@ in a few hours.", forecast];
             }
             else
             {
                 NSLog(@"could not get forecast: %@", error);
             }
         }];
        
    }];
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"failed to fetch current location : %@", error);
}





@end
