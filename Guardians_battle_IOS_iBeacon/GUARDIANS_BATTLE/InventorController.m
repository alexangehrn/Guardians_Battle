//
//  InventorController.m
//  GUARDIANS_BATTLE
//
//  Created by alexandra angehrn on 29/11/2016.
//  Copyright © 2016 alexandra angehrn. All rights reserved.
//

#import "InventorController.h"

@interface InventorController ()
@property (weak, nonatomic) IBOutlet UITableView *inventorTable;

@property (nonatomic, strong) NSMutableArray *allDamages;
@property (nonatomic, strong) NSMutableArray *allImages;
@property (nonatomic, strong) NSMutableArray *allAttacks;
@property (nonatomic, strong) NSMutableArray *selfDamages;
@property (nonatomic, strong) NSMutableArray *selfImages;
@property (nonatomic, strong) NSMutableArray *selfAttacks;
@end

@implementation InventorController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.topItem.title = @"Attaques";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"userToken"];
    NSURL *url = [NSURL URLWithString:@"http://mogue.etudiant-eemi.com/perso/Workshop/index.php/api/getAttacks"];
    
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
                                                  
                                                  _allAttacks = [NSMutableArray new];
                                                  _allDamages= [NSMutableArray new];
                                                  _allImages= [NSMutableArray new];
                                                  
                                                  
                                                  for (id myArrayElement in jsonFromData) {
                                                      NSLog(@"%@", myArrayElement);
                                                      
                                                      [_allAttacks addObject:[myArrayElement objectForKey:@"attack_name"]];
                                                      [_allDamages addObject:[myArrayElement objectForKey:@"attack_damage"]];
                                                      [_allImages addObject:[myArrayElement objectForKey:@"attack_image"]];
                                                      
                                                  }
                                                  [self.inventorTable reloadData];
                                                  
                                              });
                                              
                                          }
                                      }];
    
    [dataTask resume];
    NSURL *url2 = [NSURL URLWithString:@"http://mogue.etudiant-eemi.com/perso/Workshop/index.php/api/getAttacksUser"];
    
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
                                                    
                                                    _selfDamages = [NSMutableArray new];
                                                    _selfImages= [NSMutableArray new];
                                                    _selfAttacks= [NSMutableArray new];
                                                    
                                                    
                                                    for (id myArrayElement in jsonFromData) {
                                                        NSLog(@"%@", myArrayElement);
                                                        
                                                        [_selfAttacks addObject:[myArrayElement valueForKey:@"attack_name"]];
                                                        
                                                        [_selfImages addObject:[myArrayElement valueForKey:@"attack_image"]];
                                                        
                                                        [_selfDamages addObject:[myArrayElement valueForKey:@"attack_damage"]];
                                                        
                                                        
                                                    }
                                                    [self.inventorTable reloadData];
                                                    
                                                });
                                                
                                            }
                                        }];
    
    [dataSecond resume];
    
    
    NSLog(@"%@",_allAttacks);
    
    _allAttacks = [NSMutableArray arrayWithObjects:@"Noms", nil];
    _selfAttacks = [NSMutableArray arrayWithObjects:@"Noms", nil];
    _inventorTable.dataSource = self;
    _inventorTable.delegate = self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    if (section == 0)
        return [_selfAttacks count];
    if (section == 1)
        return [_allAttacks count];
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
    }
    
    if (indexPath.section==0) {
        
        cell.textLabel.text = [_selfAttacks objectAtIndex:indexPath.row];
        
        NSString *attack = [NSString stringWithFormat:@"%@%@", @"Dommages ",[_selfDamages objectAtIndex:indexPath.row]];
        
        cell.detailTextLabel.text = attack;
        
        cell.imageView.image = [UIImage imageNamed:[_selfImages objectAtIndex:indexPath.row]];
    }
    
    if (indexPath.section==1) {
        
        cell.textLabel.text = [_allAttacks objectAtIndex:indexPath.row];
        
        NSString *attack = [NSString stringWithFormat:@"%@%@", @"Dommages ",[_allDamages objectAtIndex:indexPath.row]];
        
        cell.detailTextLabel.text = attack;
        
        cell.imageView.image = [UIImage imageNamed:[_allImages objectAtIndex:indexPath.row]];
    }
    
    return cell;
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"mes attaques";
    if (section == 1)
        return @"toutes les attaques";
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
