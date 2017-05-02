//
//  AttacksController.m
//  GUARDIANS_BATTLE
//
//  Created by alexandra angehrn on 29/11/2016.
//  Copyright © 2016 alexandra angehrn. All rights reserved.
//

#import "AttacksController.h"
#import "TabController.h"

@interface AttacksController ()
@property (weak, nonatomic) IBOutlet UITableView *inventorTable;
@property (nonatomic, strong) NSMutableArray *selfDamages;
@property (nonatomic, strong) NSMutableArray *selfImages;
@property (nonatomic, strong) NSMutableArray *selfAttacks;
@property (nonatomic, assign) NSInteger guardian;
@end

@implementation AttacksController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.topItem.title = @"Attaques Spéciales";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"userToken"];

    NSURL *url2 = [NSURL URLWithString:@"http://mogue.etudiant-eemi.com/perso/Workshop/index.php/api/getAttacksUser"];
    
    
    NSMutableURLRequest *request2 =[NSMutableURLRequest requestWithURL:url2];
    [request2 setHTTPMethod:@"GET"];
    
    [request2 setValue:token forHTTPHeaderField:@"S-Token"];

    
    NSURLSessionDataTask *dataSecond = [[NSURLSession sharedSession]
                                        dataTaskWithRequest:request2 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                        {
                                            NSDictionary* jsonFromData = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                            
                                            NSLog(@"%@",jsonFromData);

                                            if (!jsonFromData ){
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    NSLog(@"echec");
                                                });
                                            }
                                            else{
                                                NSLog(@"%@",jsonFromData);

                                                
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    
                                                    _selfDamages = [NSMutableArray new];
                                                    _selfImages= [NSMutableArray new];
                                                    _selfAttacks= [NSMutableArray new];
                                                    
                                                    
                                                    for (id myArrayElement in jsonFromData) {
                                                        NSLog(@"aaaa %@", myArrayElement);
                                                        
                                                        [_selfAttacks addObject:[myArrayElement valueForKey:@"attack_name"]];
                                                        
                                                        [_selfImages addObject:[myArrayElement valueForKey:@"attack_image"]];
                                                        
                                                        [_selfDamages addObject:[myArrayElement valueForKey:@"attack_damage"]];
                                                        
                                                        
                                                    }
                                                    [self.inventorTable reloadData];
                                                    
                                                });
                                                
                                            }
                                        }];
    
    [dataSecond resume];
    _selfAttacks = [NSMutableArray arrayWithObjects:@"Noms", nil];
    
    _inventorTable.dataSource = self;
    _inventorTable.delegate = self;


}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"AAAAAAA %@ ", _selfAttacks);

        return [_selfAttacks count];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
    }
    
    
        cell.textLabel.text = [_selfAttacks objectAtIndex:indexPath.row];
        
        NSString *attack = [NSString stringWithFormat:@"%@%@", @"Dommages ",[_selfDamages objectAtIndex:indexPath.row]];
        
        cell.detailTextLabel.text = attack;
        
        cell.imageView.image = [UIImage imageNamed:[_selfImages objectAtIndex:indexPath.row]];
    

    
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"userToken"];
    
    NSURL *url2 = [NSURL URLWithString:@"http://mogue.etudiant-eemi.com/perso/Workshop/index.php/api/getAttacksUser"];
    
    
    NSMutableURLRequest *request2 =[NSMutableURLRequest requestWithURL:url2];
    [request2 setHTTPMethod:@"GET"];
    
    [request2 setValue:token forHTTPHeaderField:@"S-Token"];
    
    
    NSURLSessionDataTask *dataSecond = [[NSURLSession sharedSession]
                                        dataTaskWithRequest:request2 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                        {
                                            NSDictionary* jsonFromData = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                            
                                            NSLog(@"%@",jsonFromData);
                                            
                                            if (!jsonFromData ){
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    NSLog(@"echec");
                                                });
                                            }
                                            else{
                                                NSLog(@"%@",jsonFromData);
                                                
                                                
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    
                                                    _selfDamages = [NSMutableArray new];
                                                    _selfImages= [NSMutableArray new];
                                                    _selfAttacks= [NSMutableArray new];
                                                    
                                                    
                                                    for (id myArrayElement in jsonFromData) {
                                                     
                                                        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                                                        NSString *name = cell.text;
                                                        
                                                        if([name isEqualToString:[myArrayElement valueForKey:@"attack_name"]]){
                                                            NSString *damage = [myArrayElement valueForKey:@"attack_damage"];
                                                            int damageUser = [damage intValue];

                                                        
                                                            NSString *iHpGuardian_string = self.hp;
                                                            
                                                            int iHpGuardian = [iHpGuardian_string intValue];
                                                            double randUser = 1 + (random() * (4));
             
                                                            int iNewHpGuardian = iHpGuardian - damageUser;
                                                            
                                                            NSLog(@"damage");
                                                            
                                                            if(iNewHpGuardian > 0){
                                                                
                                                                NSString* new_hp_guardian = [NSString stringWithFormat:@"%i", iNewHpGuardian];
                                                                self.hp = new_hp_guardian;
                                                        
                                                                
                                                                
                                                                double randGuardian = 1 + arc4random() % (4);
                                                                NSLog(@"damage gardien %f", randGuardian);
                                                                if (randGuardian < 2){
                                                                    self.guardian = self.guardian * 2;
                                                                }
                                                                
                                                                NSString *iHpUser_string = self.hp;
                                                                int iHpUser = [iHpUser_string intValue];
                                                                
                                                                NSInteger iNewHpUser = iHpUser - self.guardian;
                                                                
                                                                NSString *new_hp_user = [NSString stringWithFormat:@"%li", (long)iNewHpUser];
                                                                if(iNewHpUser > 0){
                                                                    FightController *tabController=[self.storyboard instantiateViewControllerWithIdentifier:@"fight"];
                                                                    tabController.guardianLife = iNewHpGuardian;

                                                                    tabController.userLife = iNewHpUser;
                                                                    [self.navigationController pushViewController:tabController animated:YES];
                                                                    
                                                                }
                                                                else{
                                                                    
                                                                    NSLog(@"Redirige defaite");             
                                                                    TabController *tabController=[self.storyboard instantiateViewControllerWithIdentifier:@"tab"];
                                                                    tabController.responseGame = @"Défaite";
                                                                    [self.navigationController pushViewController:tabController animated:YES];
                                                                }
                                                                
                                                            }
                                                            else{
                                                                
                                                                NSLog(@"Redirige victoire");
                                                                TabController *tabController=[self.storyboard instantiateViewControllerWithIdentifier:@"tab"];
                                                                tabController.responseGame = @"Victoire \n Vous obtenez un monument et une attaque";
                                                                NSString *guardien_id = [NSString stringWithFormat:@"%li", self.id];
                                                                tabController.guardienId = guardien_id;
                                                                [self.navigationController pushViewController:tabController animated:YES];
                                                                
                                                            }

                                                        }
                                                        
                                                    }
                                                    
                                                });
                                                
                                            }
                                        }];
    
    [dataSecond resume];
    
 
    
    
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
