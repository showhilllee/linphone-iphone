/* ContactDetailsViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */              

#import "ContactDetailsViewController.h"
#import "PhoneMainView.h"

@implementation ContactDetailsViewController

@synthesize tableController;
@synthesize contact;
@synthesize editButton;
@synthesize backButton;
@synthesize cancelButton;


#pragma mark - Lifecycle Functions

- (id)init  {
    self = [super initWithNibName:@"ContactDetailsViewController" bundle:[NSBundle mainBundle]];
    if(self != nil) {
        inhibUpdate = FALSE;
        addressBook = ABAddressBookCreate();
        ABAddressBookRegisterExternalChangeCallback(addressBook, sync_address_book, self);
    }
    return self;
}

- (void)dealloc {
    ABAddressBookUnregisterExternalChangeCallback(addressBook, sync_address_book, self);
    CFRelease(addressBook);
    [tableController release];
    
    [editButton release];
    [backButton release];
    [cancelButton release];
    
    [super dealloc];
}


#pragma mark - 

- (void)resetData {
    if(contact == NULL) {
        ABAddressBookRevert(addressBook);
        return;
    }
    
    [LinphoneLogger logc:LinphoneLoggerLog format:"Reset data to contact %p", contact];
    ABRecordID recordID = ABRecordGetRecordID(contact);
    ABAddressBookRevert(addressBook);
    contact = ABAddressBookGetPersonWithRecordID(addressBook, recordID);
    if(contact == NULL) {
        [[PhoneMainView instance] popCurrentView];
        return;
    }
    [tableController setContact:contact];
}

static void sync_address_book (ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    ContactDetailsViewController* controller = (ContactDetailsViewController*)context;
    if(!controller->inhibUpdate && ![[controller tableController] isEditing]) {
        [controller resetData];
    }
}

- (void)removeContact {
    if(contact == NULL) {
        [[PhoneMainView instance] popCurrentView];
        return;
    }
    
    // Remove contact from book
    if(ABRecordGetRecordID(contact) != kABRecordInvalidID) {
        NSError* error = NULL;
        ABAddressBookRemoveRecord(addressBook, contact, (CFErrorRef*)&error);
        if (error != NULL) {
            [LinphoneLogger log:LinphoneLoggerError format:@"Remove contact %p: Fail(%@)", contact, [error localizedDescription]];
        } else {
            [LinphoneLogger logc:LinphoneLoggerLog format:"Remove contact %p: Success!", contact];
        }
        contact = NULL;
        
        // Save address book
        error = NULL;
        inhibUpdate = TRUE;
        ABAddressBookSave(addressBook, (CFErrorRef*)&error);
        inhibUpdate = FALSE;
        if (error != NULL) {
            [LinphoneLogger log:LinphoneLoggerError format:@"Save AddressBook: Fail(%@)", [error localizedDescription]];
        } else {
            [LinphoneLogger logc:LinphoneLoggerLog format:"Save AddressBook: Success!"];
        }
    }
}

- (void)saveData {
    if(contact == NULL) {
        [[PhoneMainView instance] popCurrentView];
        return;
    }
    
    // Add contact to book
    NSError* error = NULL;
    if(ABRecordGetRecordID(contact) == kABRecordInvalidID) {
        ABAddressBookAddRecord(addressBook, contact, (CFErrorRef*)&error);
        if (error != NULL) {
            [LinphoneLogger log:LinphoneLoggerError format:@"Add contact %p: Fail(%@)", contact, [error localizedDescription]];
        } else {
            [LinphoneLogger logc:LinphoneLoggerLog format:"Add contact %p: Success!", contact];
        }
    }
    
    // Save address book
    error = NULL;
    inhibUpdate = TRUE;
    ABAddressBookSave(addressBook, (CFErrorRef*)&error);
    inhibUpdate = FALSE;
    if (error != NULL) {
        [LinphoneLogger log:LinphoneLoggerError format:@"Save AddressBook: Fail(%@)", [error localizedDescription]];
    } else {
        [LinphoneLogger logc:LinphoneLoggerLog format:"Save AddressBook: Success!"];
    }
}

- (void)newContact {
    [LinphoneLogger logc:LinphoneLoggerLog format:"New contact"];
    self->contact = ABPersonCreate();
    [tableController setContact:self->contact];
    [self enableEdit:FALSE];
    [[tableController tableView] reloadData];
}

- (void)newContact:(NSString*)address {
    [LinphoneLogger logc:LinphoneLoggerLog format:"New contact"];
    self->contact = ABPersonCreate();
    [tableController setContact:self->contact];
    [tableController addSipField:address];
    [self enableEdit:FALSE];
    [[tableController tableView] reloadData];
}

- (void)editContact:(ABRecordRef)acontact {
    [LinphoneLogger logc:LinphoneLoggerLog format:"Edit contact %p", acontact];
    self->contact = ABAddressBookGetPersonWithRecordID(addressBook, ABRecordGetRecordID(acontact));
    [tableController setContact:self->contact];
    [self enableEdit:FALSE];
    [[tableController tableView] reloadData];
}

- (void)editContact:(ABRecordRef)acontact address:(NSString*)address {
    [LinphoneLogger logc:LinphoneLoggerLog format:"Edit contact %p", acontact];
    self->contact = ABAddressBookGetPersonWithRecordID(addressBook, ABRecordGetRecordID(acontact));
    [tableController setContact:self->contact];
    [tableController addSipField:address];
    [self enableEdit:FALSE];
    [[tableController tableView] reloadData];
}


#pragma mark - Property Functions

- (void)setContact:(ABRecordRef)acontact {
    [LinphoneLogger logc:LinphoneLoggerLog format:"Set contact %p", acontact];
    self->contact = ABAddressBookGetPersonWithRecordID(addressBook, ABRecordGetRecordID(acontact));
    [tableController setContact:self->contact];
    [self disableEdit:FALSE];
}


#pragma mark - ViewController Functions

- (void)viewDidLoad{
    [super viewDidLoad];
    // Set selected+over background: IB lack !
    [editButton setImage:[UIImage imageNamed:@"contact_ok_over.png"] 
                forState:(UIControlStateHighlighted | UIControlStateSelected)];
    
    // Force view load
    [tableController->footerController view];
    [tableController->footerController->removeButton addTarget:self 
                                                        action:@selector(onRemove:) 
                                              forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [tableController->footerController->removeButton removeTarget:self 
                                                           action:@selector(onRemove:) 
                                                 forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [tableController viewWillDisappear:animated];
    }
    [self disableEdit:FALSE];
    self->contact = NULL;
    [self resetData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if([ContactSelection getSelectionMode] == ContactSelectionModeEdit ||
       [ContactSelection getSelectionMode] == ContactSelectionModeNone) {
        [editButton setHidden:FALSE];
    } else {
        [editButton setHidden:TRUE];
    }
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [tableController viewWillAppear:animated];
    }   
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [tableController viewDidAppear:animated];
    }   
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [tableController viewDidDisappear:animated];
    }  
}


#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"ContactDetails" 
                                                                content:@"ContactDetailsViewController" 
                                                               stateBar:nil 
                                                        stateBarEnabled:false 
                                                                 tabBar:@"UIMainBar" 
                                                          tabBarEnabled:true 
                                                             fullscreen:false];
    }
    return compositeDescription;
}


#pragma mark -

- (void)enableEdit:(BOOL)animated {
    if(![tableController isEditing]) {
        [tableController setEditing:TRUE animated:animated];
    }
    [editButton setOn];
    [cancelButton setHidden:FALSE];
    [backButton setHidden:TRUE];
}

- (void)disableEdit:(BOOL)animated {
    if([tableController isEditing]) {
        [tableController setEditing:FALSE animated:animated];
    }
    [editButton setOff];
    [cancelButton setHidden:TRUE];
    [backButton setHidden:FALSE];
}

#pragma mark - Action Functions

- (IBAction)onCancelClick:(id)event {
    [self disableEdit:TRUE];
    [self resetData];
}

- (IBAction)onBackClick:(id)event {
    [[PhoneMainView instance] popCurrentView];
}

- (IBAction)onEditClick:(id)event {
    if([tableController isEditing]) {
        [self disableEdit:TRUE];
        [self saveData];
    } else {
        [self enableEdit:TRUE];
    }
}

- (void)onRemove:(id)event {
    [self disableEdit:FALSE];
    [self removeContact];
    [[PhoneMainView instance] popCurrentView];
}

@end