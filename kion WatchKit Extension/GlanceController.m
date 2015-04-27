//
//  GlanceController.m
//  test WatchKit Extension
//
//  Created by Mario Delgado on 4/25/15.
//  Copyright (c) 2015 Mario Delgado. All rights reserved.
//

#import "GlanceController.h"
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

@interface GlanceController()
@property (nonatomic, readwrite) CLLocationCoordinate2D mycord;
@property (nonatomic, readwrite) CLLocationDegrees lat;
@property (nonatomic, readwrite) CLLocationDegrees lon;
@property NSDictionary *result;
@property (nonatomic, strong) KFOpenWeatherMapAPIClient *apiClient;
@property (nonatomic, weak) NSString *condi;
@property (nonatomic, weak) NSDate *sunrise;
@property (nonatomic, weak) NSDate *sunset;
@property (nonatomic, weak) NSDate *time;

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *Location;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *weatherCond;



@end


@implementation GlanceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    
    locationManager = [[CLLocationManager alloc] init];
    [locationManager requestWhenInUseAuthorization];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    geocoder = [[CLGeocoder alloc] init];
    
    locationFetchCounter = 0;
    
    [locationManager requestAlwaysAuthorization];
    // fetching current location start from here
    [locationManager startUpdatingLocation];
    
    
    [self startup];
    
//    NSArray *objects = [[NSArray alloc] initWithObjects: @"%@", self.location, @"%@", self.condition, nil];
//    NSArray *keys = [[NSArray alloc] initWithObjects:@"location1", @"cond", nil];

//    NSString *requestString = [NSString stringWithFormat:@"executeMethodA"]; // This string is arbitrary, just must match here and at the iPhone side of the implementation.
//    NSDictionary *applicationData = [[NSDictionary alloc] initWithObjects:@[requestString] forKeys:@[@"theRequestString"]];
//  NSDictionary *replyInfo = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
//    
//
//    [WKInterfaceController openParentApplication:applicationData reply:^(NSDictionary *replyInfo, NSError *error) {
//        NSLog(@"\nReply info: %@\nError: %@",replyInfo, error);
//        self.location = [replyInfo objectForKey:@"location1"];
//        self.condition = [replyInfo objectForKey:@"cond"];
//        
//        self.loc.text = self.location;
//        self.cond.text = [NSString stringWithFormat:@"It will be %@ tomorrow", self.condition];
//        
//    }];
    
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    [locationManager stopUpdatingLocation];

}

-(void)startup{

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
                 self.Location.text = upper1;
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
                self.weatherCond.text= [NSString stringWithFormat:@"It will probably be %@ later.", forecast];
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



