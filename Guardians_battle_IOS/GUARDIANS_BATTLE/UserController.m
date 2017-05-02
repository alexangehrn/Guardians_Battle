//
//  UserController.m
//  GUARDIANS_BATTLE
//
//  Created by alexandra angehrn on 01/12/2016.
//  Copyright © 2016 alexandra angehrn. All rights reserved.
//

#import "UserController.h"
#import "TabController.h"

@interface UserController ()
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *loginField;
@property (weak, nonatomic) IBOutlet UITextField *passField;
@property (weak, nonatomic) NSString *personnage;

@end

@implementation UserController
- (IBAction)perso1Button:(id)sender {
    self.personnage=@"1";
}
- (IBAction)perso2Button:(id)sender {
    self.personnage=@"2";
}
- (IBAction)perso3Button:(id)sender {
    self.personnage=@"3";
}
- (IBAction)perso4Button:(id)sender {
    self.personnage=@"4";
}
- (IBAction)updateButton:(id)sender {
    NSString *login = [self.loginField text];
    NSString *perso = self.personnage;
    NSString *pass = [self.passField text];
    NSString *email = [self.emailField text];
    
    NSURL *url = [NSURL URLWithString:@"http://mogue.etudiant-eemi.com/perso/Workshop/index.php/api/updateUser?"];
    
    
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSString *post =[[NSString alloc] initWithFormat:@"username=%@&password=%@&usermail=%@&useravatar=%@",login,pass,email,perso];
    
    [request setHTTPBody:[post dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"userToken"];
    NSLog(@"%@",post);
    
    [request setValue:token forHTTPHeaderField:@"S-Token"];
    
    
    // NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]
                                      dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          
                                          NSLog(@"%@", data);
                                          NSDictionary* jsonFromData = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                          
                                          if (!jsonFromData ){
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  
                                                  NSString *title = @"Erreur";
                                                  NSString *message = @"Un probleme à eu lieu!";
                                                  NSString *actionRetry = @"Réessayer";
                                                  
                                                  
                                                  UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                                                                 message:message
                                                                                                          preferredStyle:UIAlertControllerStyleAlert];
                                                  UIAlertAction *firstAction = [UIAlertAction actionWithTitle:actionRetry
                                                                                                        style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                                                        }];
                                                  
                                                  [alert addAction:firstAction];
                                                  
                                                  [self presentViewController:alert animated:YES completion:nil];
                                              });
                                          }
                                          else{
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  
                                                  
                                                  NSString *title = @"Bravo";
                                                  NSString *message = @"Votre compte a été modifié!";
                                                  NSString *actionRetry = @"Revenir à l'accueil";
                                                  
                                                  
                                                  UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                                                                 message:message
                                                                                                          preferredStyle:UIAlertControllerStyleAlert];
                                                  UIAlertAction *firstAction = [UIAlertAction actionWithTitle:actionRetry
                                                                                                        style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                
                                                                                                                TabController *rc =[self.storyboard instantiateViewControllerWithIdentifier:@"tab"];
                                                                                                                [self.navigationController pushViewController:rc animated:YES];
                                                                                                            });
                                                                                                            
                                                                                                        }];
                                                  
                                                  [alert addAction:firstAction];
                                                  
                                                  [self presentViewController:alert animated:YES completion:nil];
                                                  
                                              });
                                          }
                                      }];
    
    [dataTask resume];
    
}
- (IBAction)deleteButton:(id)sender {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"userToken"];
    NSURL *url = [NSURL URLWithString:@"http://mogue.etudiant-eemi.com/perso/Workshop/index.php/api/userSettings?"];
    
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    [request setValue:token forHTTPHeaderField:@"S-Token"];
    
    
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]
                                      dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          if (data == nil){
                                              NSLog(@"probleme");
                                          }
                                          NSDictionary* jsonFromData = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                          NSLog(@"%@",jsonFromData);
                                          
                                          
                                          if (!jsonFromData ){
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  
                                              });
                                          }
                                          else{
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  for (NSString *item in jsonFromData) {
                                                      self.loginField.text =[item valueForKey:@"username"];
                                                      self.passField.text=[item valueForKey:@"password"];
                                                      self.emailField.text=[item valueForKey:@"usermail"];
                                                      _personnage =[item valueForKey:@"useravatar"];
                                                      
                                                  }
                                                  
                                                  
                                                  //[self.passField setText:[jsonFromData valueForKey:@"password"]];
                                                  
                                                  //[self.emailField setText:[jsonFromData valueForKey:@"usermail"]];
                                                  //_personnage =[jsonFromData valueForKey:@"useravatar"];
                                                  
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
