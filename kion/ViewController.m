//
//  ViewController.m
//  kion
//
//  Created by Mario C. Delgado Jr. on 3/29/15.
//  Copyright (c) 2015 Mario C. Delgado Jr. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
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
#import <AVFoundation/AVFoundation.h>
#import "MMWormhole.h"

CLLocationManager *locationManager;
CLGeocoder *geocoder;
int locationFetchCounter;
int refreshcounter;



@interface ViewController () <CLLocationManagerDelegate>

@property (nonatomic, readwrite) CLLocationCoordinate2D mycord;
@property (nonatomic, readwrite) CLLocationDegrees lat;
@property (nonatomic, readwrite) CLLocationDegrees lon;
@property NSDictionary *result;
@property (nonatomic, strong) KFOpenWeatherMapAPIClient *apiClient;
@property (nonatomic, weak) NSString *condi;
@property (nonatomic, weak) NSDate *sunrise;
@property (nonatomic, weak) NSDate *sunset;
@property (nonatomic, weak) NSDate *time;
@property (weak, nonatomic) IBOutlet UILabel *weatherCond;
@property (weak, nonatomic) IBOutlet UILabel *Location;
@property BOOL daytime;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self startup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}


-(void)startup{
    locationManager = [[CLLocationManager alloc] init];
    [locationManager requestWhenInUseAuthorization];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    geocoder = [[CLGeocoder alloc] init];
    
    locationFetchCounter = 0;

        [locationManager requestAlwaysAuthorization];
    // fetching current location start from here
    [locationManager startUpdatingLocation];
}

- (IBAction)didPressSendNotificationsButton:(id)sender {
    
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
    localNotification.alertBody = @"User notification!";
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
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
                 
                 self.weatherCond.text= upper2;
                 NSLog(@"It's %@", upper2);
                 
                 NSString *loc1 = [NSString stringWithFormat:@"%@", responseModel.cityName];
                 NSString *upper1 = [loc1 uppercaseString];
                 self.Location.text = upper1;
                 NSLog(@"It's %@", upper1);
                 NSArray *keys = @[@"location", @"condition"];
                 NSArray *objects = [NSArray arrayWithObjects:@"%@",loc1, @"%@",upper1, nil];

                 NSDictionary *dataDict = [NSDictionary dictionaryWithObject:@"objects"
                            forKey:@"keys"];
                 
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"conditions" object:self userInfo:dataDict];
                 
             }}];
        
    }];
   
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"failed to fetch current location : %@", error);
   }

@end
