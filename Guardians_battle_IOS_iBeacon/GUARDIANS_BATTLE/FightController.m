//
//  FightController.m
//  GUARDIANS_BATTLE
//
//  Created by alexandra angehrn on 29/11/2016.
//  Copyright © 2016 alexandra angehrn. All rights reserved.
//

#import "FightController.h"
#import "AttacksController.h"
#import "TabController.h"

@interface FightController ()
@property (weak, nonatomic) IBOutlet UILabel *guardian_name_field;
@property (weak, nonatomic) IBOutlet UILabel *user_name_field;
@property (weak, nonatomic) IBOutlet UILabel *guardian_life_field;
@property (weak, nonatomic) IBOutlet UILabel *user_life_field;
@property (weak, nonatomic) IBOutlet UIButton *simpleAttaque;
@property (readwrite) NSInteger guardien_damage;
@property (readwrite) NSInteger guardienId;

@end

@implementation FightController

//NSUInteger *guardien_damage;

- (IBAction)specialAttackButton:(id)sender {
    AttacksController *rc =[self.storyboard instantiateViewControllerWithIdentifier:@"attacks"];
    NSString *data = [self.guardian_life_field text]; // Contenu du champ de recherche
    long id = self.guardienId; // Contenu du champ de recherche
    rc.hp = data;
    rc.id = id;
    [self.navigationController pushViewController:rc animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    

    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"userToken"];
    NSURL *url = [NSURL URLWithString:@"http://mogue.etudiant-eemi.com/perso/Workshop/index.php/api/getMonument/f2a74fc4-7625-44db-9b08-cb7e130b2029-65535-384"];
    
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
                                                  
                                                self.guardian_life_field.text = [jsonFromData valueForKey:@"monument_attack"];
                                                  
                                                self.guardian_name_field.text = [jsonFromData valueForKey:@"monument_guardian_name"];
                                                  
                                                self.user_life_field.text = @"100";
                                                  
                                                self.user_name_field.text = @"Combattant";
                                                  
                                                _guardien_damage = [[jsonFromData valueForKey:@"monument_guardian_damage"] intValue];
                                                  
                                                _guardienId = [[jsonFromData valueForKey:@"ID_monument"] intValue];
                                                  
                                                  if( _userLife != 0){
                                                      NSLog(@"user");
                                                      NSString *life =[NSString stringWithFormat:@"%li", (long)_userLife];
                                                      NSLog(@"%@", life);
                                                      
                                                      self.user_life_field.text = life;
                                                      
                                                  }
                                                  if( _guardianLife != 0){
                                                      NSString *life =[NSString stringWithFormat:@"%li", (long)_guardianLife];
                                                      NSLog(@"%@", life);
                                                      
                                                      self.guardian_life_field.text = life;
                                                      NSLog(@"%@", self.guardian_life_field.text);
                                                      
                                                  }
                                                  
                                              });
                                            
                                          }
                                      }];
    
    [dataTask resume];
    

    

    NSLog(@" UGUARD LIFE %ld",_guardianLife);

}

- (IBAction)SimpleAttackButton:(id)sender {
    
    NSString *iHpGuardian_string = self.guardian_life_field.text;
    int iHpGuardian = [iHpGuardian_string intValue];
    int damageUser = 0;
    double randUser = 1 + (random() * (4));
    
    if (randUser < 2){
        damageUser = 30;
    }
    else{
        damageUser = 10;
    }
    
    int iNewHpGuardian = iHpGuardian - damageUser;
    
    NSLog(@"damage");
    
    if(iNewHpGuardian > 0){
        
        NSString* new_hp_guardian = [NSString stringWithFormat:@"%i", iNewHpGuardian];
        self.guardian_life_field.text = new_hp_guardian;
        NSInteger damageGuardian = _guardien_damage;
        
        NSLog(@"damage gardien %ld", (long)damageGuardian);
        
        double randGuardian = 1 + arc4random() % (4);
        NSLog(@"damage gardien %f", randGuardian);
         if (randGuardian < 2){
         damageGuardian = damageGuardian * 2;
         }
         
        NSString *iHpUser_string = self.user_life_field.text;
        int iHpUser = [iHpUser_string intValue];
         
        NSInteger iNewHpUser = iHpUser - damageGuardian;
        
        NSString *new_hp_user = [NSString stringWithFormat:@"%li", (long)iNewHpUser];
         if(iNewHpUser > 0){
             self.user_life_field.text = new_hp_user;
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
             NSString *guardien_id = [NSString stringWithFormat:@"%li", _guardienId];
             tabController.guardienId = guardien_id;
             [self.navigationController pushViewController:tabController animated:YES];

         }
    

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
