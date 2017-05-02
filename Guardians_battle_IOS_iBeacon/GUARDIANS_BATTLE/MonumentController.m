//
//  MonumentController.m
//  GUARDIANS_BATTLE
//
//  Created by alexandra angehrn on 29/11/2016.
//  Copyright © 2016 alexandra angehrn. All rights reserved.
//

#import "MonumentController.h"

@interface MonumentController ()
@property (weak, nonatomic) IBOutlet UITableView *monumentTable;
@property (nonatomic, strong) NSMutableArray *allMonuments;
@property (nonatomic, strong) NSMutableArray *allLevels;
@property (nonatomic, strong) NSMutableArray *allImages;
@property (nonatomic, strong) NSMutableArray *allAttacks;
@property (nonatomic, strong) NSMutableArray *selfMonuments;
@property (nonatomic, strong) NSMutableArray *selfLevels;
@property (nonatomic, strong) NSMutableArray *selfImages;
@property (nonatomic, strong) NSMutableArray *selfAttacks;

@end

@implementation MonumentController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.topItem.title = @"Monuments";
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
                                                  
                                                  _allMonuments = [NSMutableArray new];
                                                  _allLevels= [NSMutableArray new];
                                                  _allAttacks= [NSMutableArray new];
                                                  
                                                  
                                                  for (id myArrayElement in jsonFromData) {
                                                      NSLog(@"%@", myArrayElement);
                                                      
                                                      [_allMonuments addObject:[myArrayElement objectForKey:@"monument_name"]];
                                                      [_allLevels addObject:[myArrayElement objectForKey:@"monument_level"]];
                                                      [_allAttacks addObject:[myArrayElement objectForKey:@"monument_attack"]];
                                                      [_allImages addObject:[myArrayElement objectForKey:@"monument_image"]];
                                                  }
                                                  [self.monumentTable reloadData];
                                                  
                                                  
                                              });
                                              
                                          }
                                      }];
    
    [dataTask resume];
    
    
    
    NSURL *url2 = [NSURL URLWithString:@"http://mogue.etudiant-eemi.com/perso/Workshop/index.php/api/getMonumentsUser"];
    
    NSMutableURLRequest *request2 =[NSMutableURLRequest requestWithURL:url2];
    [request2 setHTTPMethod:@"GET"];
    
    [request2 setValue:token forHTTPHeaderField:@"S-Token"];
    
    
    NSURLSessionDataTask *dataSecond = [[NSURLSession sharedSession]
                                        dataTaskWithRequest:request2 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                        {
                                            NSDictionary* jsonFromData = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                            
                                            
                                            if (!jsonFromData ){
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    NSLog(@"echec");
                                                });
                                            }
                                            else{
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    
                                                    _selfMonuments = [NSMutableArray new];
                                                    _selfLevels= [NSMutableArray new];
                                                    _selfAttacks= [NSMutableArray new];
                                                    
                                                    
                                                    for (id myArrayElement in jsonFromData) {
                                                        NSLog(@"%@", myArrayElement);
                                                        
                                                        [_selfMonuments addObject:[myArrayElement objectForKey:@"monument_name"]];
                                                        [_selfLevels addObject:[myArrayElement objectForKey:@"monument_level"]];
                                                        [_selfAttacks addObject:[myArrayElement objectForKey:@"monument_attack"]];
                                                        [_selfImages addObject:[myArrayElement objectForKey:@"monument_image"]];
                                                    }
                                                    [self.monumentTable reloadData];
                                                    
                                                });
                                                
                                            }
                                        }];
    
    [dataSecond resume];
    
    NSLog(@"%@",_allMonuments);
    _allMonuments = [NSMutableArray arrayWithObjects:@"Noms", nil];
    _selfMonuments = [NSMutableArray arrayWithObjects:@"Noms", nil];
    _monumentTable.dataSource = self;
    _monumentTable.delegate = self;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    if (section == 0)
        return [_selfMonuments count];
    if (section == 1)
        return [_allMonuments count];
    return 0;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
    }
    
    if (indexPath.section==0) {
        cell.textLabel.text = [_selfMonuments objectAtIndex:indexPath.row];
        
        NSString *attack = [NSString stringWithFormat:@"%@%@%@%@", @"Niveau ",[_selfLevels objectAtIndex:indexPath.row], @" - Attaque ",[_selfAttacks objectAtIndex:indexPath.row]];
        
        cell.detailTextLabel.text = attack;
        
        cell.imageView.image = [UIImage imageNamed:[_selfImages objectAtIndex:indexPath.row]];
        
    }
    if (indexPath.section==1){
        cell.textLabel.text = [_allMonuments objectAtIndex:indexPath.row];
        
        NSString *attack = [NSString stringWithFormat:@"%@%@%@%@", @"Niveau ",[_allLevels objectAtIndex:indexPath.row], @" - Attaque ",[_allAttacks objectAtIndex:indexPath.row]];
        
        cell.detailTextLabel.text = attack;
        
        cell.imageView.image = [UIImage imageNamed:[_allImages objectAtIndex:indexPath.row]];
        
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"mes Monuments";
    if (section == 1)
        return @"tous les monuments";
    return @"undefined";
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
