//
//  RegisterController.m
//  GUARDIANS_BATTLE
//
//  Created by alexandra angehrn on 29/11/2016.
//  Copyright © 2016 alexandra angehrn. All rights reserved.
//

#import "RegisterController.h"
#import "TabController.h"

@interface RegisterController ()
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *loginField;
@property (weak, nonatomic) IBOutlet UITextField *passField;
@property (weak, nonatomic) NSString *personnage;

@end

@implementation RegisterController
- (IBAction)perso4Button:(id)sender {
    
    self.personnage=@"4";
}

- (IBAction)perso3Button:(id)sender {
    self.personnage=@"3";
}

- (IBAction)perso2Button:(id)sender {
    self.personnage=@"2";
}

- (IBAction)perso1Button:(id)sender {
    self.personnage=@"1";
}

- (IBAction)connexionButton:(id)sender {
    NSString *login = [self.loginField text];
    NSString *perso = self.personnage;
    NSString *pass = [self.passField text];
    NSString *email = [self.emailField text];
    
    NSURL *url = [NSURL URLWithString:@"http://mogue.etudiant-eemi.com/perso/Workshop/index.php/register?"];
    
    
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSString *post =[[NSString alloc] initWithFormat:@"username=%@&password=%@&usermail=%@&useravatar=%@",login,pass,email,perso];
    NSLog(@"%@",post);
    [request setHTTPBody:[post dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLResponse *response;
    NSError *err;
    // NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]
                                      dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSDictionary* jsonFromData = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                          
                                          if (!jsonFromData ){
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  
                                                  NSString *title = @"Erreur";
                                                  NSString *message = @"Votre identifiant ou mot de passe est incorrect!";
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
                                                  
                                                  NSString *token=[jsonFromData valueForKey:@"token"];
                                                  
                                                  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                  
                                                  [defaults setObject:token forKey:@"userToken"];
                                                  [defaults synchronize];
                                                  
                                                  TabController *rc =[self.storyboard instantiateViewControllerWithIdentifier:@"tab"];
                                                  [self.navigationController pushViewController:rc animated:YES];
                                                  
                                              });
                                          }
                                      }];
    
    [dataTask resume];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.personnage=@"1";
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