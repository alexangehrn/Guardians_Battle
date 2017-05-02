//
//  MapController.m
//  GUARDIANS_BATTLE
//
//  Created by alexandra angehrn on 29/11/2016.
//  Copyright © 2016 alexandra angehrn. All rights reserved.
//

//
//  MapController.m
//  guardians_battel
//
//  Created by alexandra angehrn on 29/11/2016.
//  Copyright © 2016 alexandra angehrn. All rights reserved.
//

#import "MapController.h"
#import "FightController.h"
#import "UserController.h"
#import "ALDefaults.h"

@interface MapController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, copy, readonly) NSArray *supportedProximityUUIDs;
@end

@implementation MapController
{
    NSMutableDictionary *_beacons;
    CLLocationManager *_locationManager;
    NSMutableArray *_rangedRegions;
}

- (IBAction)accountButton:(id)sender {
    UserController *rc =[self.storyboard instantiateViewControllerWithIdentifier:@"user"];
    [self.navigationController pushViewController:rc animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _beacons.count;
}

- (void)viewDidAppear:(BOOL)animated
{
    // Start ranging when the view appears.
    [_rangedRegions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CLBeaconRegion *region = obj;
        [_locationManager startRangingBeaconsInRegion:region];
    }];
}

- (void)viewDidDisappear:(BOOL)animated
{
    // Stop ranging when the view goes away.
    [_rangedRegions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CLBeaconRegion *region = obj;
        [_locationManager stopRangingBeaconsInRegion:region];
    }];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"ranging");
}

- (void)viewDidLoad {


    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    [_locationManager requestWhenInUseAuthorization];
    
    _rangedRegions = [NSMutableArray array];
    [[ALDefaults sharedDefaults].supportedProximityUUIDs enumerateObjectsUsingBlock:^(id uuidObj, NSUInteger uuidIdx, BOOL *uuidStop) {
        NSUUID *uuid = (NSUUID *)uuidObj;
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[uuid UUIDString]];
        [_rangedRegions addObject:region];
    }];
    
    NSString *title = @"Battle";
    NSString *message = @"Vous êtes à proximité d\'un monument, voulez-vous combattre ?";
    NSString *actionYes = @"oui";
    NSString *actionNo = @"non";
    
    
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert]; // 1
    UIAlertAction *firstAction = [UIAlertAction actionWithTitle:actionYes
                                                          style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                              FightController *rc =[self.storyboard instantiateViewControllerWithIdentifier:@"fight"];
                                                              [self.navigationController pushViewController:rc animated:YES];                                                          }]; // 2
    UIAlertAction *secondAction = [UIAlertAction actionWithTitle:actionNo
                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                               
                                                           }]; // 3
    
    [alert addAction:firstAction]; // 4
    [alert addAction:secondAction]; // 5
    
    [self presentViewController:alert animated:YES completion:nil]; // 6
    
}


- (void)viewWillAppear:(BOOL)animated {
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"userToken"];
    NSURL *url = [NSURL URLWithString:@"http://mogue.etudiant-eemi.com/perso/Workshop/index.php/api/getMonuments"];
    
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    [request setValue:token forHTTPHeaderField:@"S-Token"];
    
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]
                                      dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSDictionary* jsonFromData = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                          
                                          
                                          if (!jsonFromData ){
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  NSLog(@"echec");
                                              });
                                          }
                                          else{
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  CLLocationCoordinate2D zoomLocation;
                                                  zoomLocation.latitude = 48.866667;
                                                  zoomLocation.longitude= 2.333333;
                                                  
                                                  MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 10*METERS_PER_MILE, 10*METERS_PER_MILE);
                                                  [_mapView setRegion:viewRegion animated:YES];
                                                  NSLog(@"%@", jsonFromData);
                                                  
                                                  
                                                  for(id location in jsonFromData) {
                                                      NSString *lat=[location valueForKey:@"lattitude"];
                                                      double latitude = [lat doubleValue];
                                                      NSString *longi=[location valueForKey:@"longitude"];
                                                      double longitude = [longi doubleValue];
                                                      NSString *lvl=[location valueForKey:@"monument_level"];
                                                      NSString *title=[location valueForKey:@"monument_name"];
                                                      NSString *level = [NSString stringWithFormat:@"%@%@", @"Niveau ", lvl];
                                                      MKCoordinateRegion e = {{0,0,0,0},{0,0,0,0}};
                                                      e.center.latitude =latitude;
                                                      e.center.longitude =longitude;
                                                      MapPin *eiffel = [[MapPin alloc]init];
                                                      eiffel.title = title;
                                                      eiffel.subtitle = level;
                                                      eiffel.coordinate = e.center;
                                                      [_mapView addAnnotation:eiffel];
                                                      
                                                  }
                                              });
                                              
                                          }
                                      }];
    
    [dataTask resume];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end

