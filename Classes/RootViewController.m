//
//  RootViewController.m
//  photolog
//
//  Created by psalty on 10/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

// TODO : Fetch state keep for better user experience


#import "RootViewController.h"
#import "DetailViewController.h"
#import "PhotoLogTableViewCell.h"
#import "PhotologImagePicker.h"
#import "PhotoSrcViewController.h"
#import <math.h>
static inline double radians (double degrees) {return degrees * M_PI/180;}

@implementation RootViewController
@synthesize access_token,user_id;


#pragma mark -
#pragma mark View lifecycle

+ (NSString *)extractKeyValueFromXmlElement:(GDataXMLElement *)xmlRef
{
	NSString *tmp		= [xmlRef stringValue];
	NSArray *chunks		= [tmp componentsSeparatedByString: @":"];
	NSString *keyChunk	= [chunks objectAtIndex:2];
	NSRange start		= [keyChunk rangeOfString:@"["];
	NSRange end			= [keyChunk rangeOfString:@"]"];
	NSString *retStr	= [keyChunk substringWithRange:NSMakeRange(start.location +1 , end.location - start.location -1)]; 	
	return retStr;
}

+ (NSString *)extractKeyValueFromString:(NSString *)strRef
{
	NSArray *chunks		= [strRef componentsSeparatedByString: @":"];
	NSString *keyChunk	= [chunks objectAtIndex:2];
	NSRange start		= [keyChunk rangeOfString:@"["];
	NSRange end			= [keyChunk rangeOfString:@"]"];
	NSString *retStr	= [keyChunk substringWithRange:NSMakeRange(start.location +1 , end.location - start.location -1)]; 	
	return retStr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	//self.navigationItem.rightBarButtonItem = self.editButtonItem;

	self.navigationItem.title = @"Photolog";
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshPage:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(uploadPhoto:)];
	
	if (!channel)
	{
		channel = [[[NSMutableArray alloc] init] retain];
	}	
	[self fetch];
}

- (void)refreshPage:(id)sender
{
	[channel removeAllObjects];
	[self fetch];
}

- (void)uploadPhoto:(id)sender
{
	facebook = [[Facebook alloc] init];
	[facebook authorize:fbook_api_key permissions:nil delegate:self];
	//fbdidlogin will handle login result
}

- (void) imagePicked:(UIImage *)img from:(UIViewController *)photoSourceController
{
	NSLog(@"image received");
	UIImage *newImage = [self resizeImage:img];
	
//	NSURL *api_url	= [[NSURL alloc] initWithScheme:@"http" host:@"10.0.1.2:8084" path:@"/create?target=image"];
	NSURL *api_url	= [[NSURL alloc] initWithScheme:@"http" host:HOSTNAME path:PHOTO_UPLOAD];

	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:api_url];
	[request addRequestHeader:@"User-Agent" value:@"app.photolog"];
	[request setPostValue:[NSString stringWithFormat:@"%@",self.user_id]  forKey:@"uid"];
	[request setPostValue:[NSString stringWithFormat:@"%@",self.access_token] forKey:@"access_token"];
	[request setData:UIImageJPEGRepresentation(newImage,0.5) withFileName:@"iphoto.jpg" andContentType:@"image/jpeg" forKey:@"pics"];
	[request start];
	
	if ([request error])
	{
		// Error throw an alert ** Could not logon to game server **
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not logon to game server" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	else if ([request responseString])
	{
		// A valid http request, but it the server curently does not see the post vars in the web application
		NSLog (@"[DEBUG]: HTTP Response is %@",[request responseString]);
	}
	//[newImage release];
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/


/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */

#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [channel count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	NSUInteger indexes[2];
	[indexPath getIndexes:indexes];	

	Content *tmp = (Content *)[channel objectAtIndex:indexes[1]];
	if(tmp)
	{
		return tmp.thumb_med.size.height/1.5 +10;// add padding
	}
	return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"ListViewCell";
	NSUInteger indexes[2];
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	UIImageView *thumbView;
	
	[indexPath getIndexes:indexes];	
	// Configure the cell.
	Content *tmp = (Content *)[channel objectAtIndex:indexes[1]];
	if(tmp)
	{
		if (cell == nil) {
/* original implementation. I added subview here instead
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
 */
			cell = [[[PhotoLogTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
			thumbView = [[[UIImageView alloc] initWithImage:[tmp.thumb_med initWithCGImage:tmp.thumb_med.CGImage scale:1.5 orientation:UIImageOrientationUp]] autorelease];
			thumbView.tag = PHOTO_TAG;

			[cell.contentView addSubview:thumbView];		
			
		}
		else
		{
			thumbView = (UIImageView *)[cell.contentView viewWithTag:PHOTO_TAG];
			thumbView.image = [tmp.thumb_med initWithCGImage:tmp.thumb_med.CGImage scale:1.5 orientation:UIImageOrientationUp] ;
			[thumbView setFrame:CGRectMake(0,0,tmp.thumb_med.size.width, tmp.thumb_med.size.height)];
		}
		[cell setContent_text:tmp.text];
		[cell setContent_title:tmp.title];
	}
	
	CGPoint p = thumbView.center;
	p.x = 160.0;

	[thumbView setCenter:p];
    return cell;
}
	
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
/*
	
	UITableViewCell *tvc = [tableView cellForRowAtIndexPath:indexPath];
	[tvc showDetailInfo:self];
*/	
	
	
	static NSUInteger indexes[2];
	DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:[NSBundle mainBundle]];
     // Pass the selected object to the new view controller.
	[indexPath getIndexes:indexes];
	detailViewController.thisContent = (Content *)[channel objectAtIndex:indexes[1]];
	[self.navigationController pushViewController:detailViewController animated:YES];
	[detailViewController release];
	detailViewController = nil; 

}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
	[channel release];
	[selectedIndex release];
	[facebook release];
	[access_token release];
	[user_id release];	
}

- (void)fetch{
	NSURL *api_url	= [[NSURL alloc] initWithScheme:@"http" host:HOSTNAME path:PHOTO_LIST_ALL];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:api_url];
	[request setDelegate:self];
	[request startAsynchronous];
}


- (void)requestFinished:(ASIHTTPRequest *)request{
	// Use when fetching text data
	NSString *responseString = [request responseString];
	
	[self parseGData:responseString];
	[self.tableView reloadData];	
	// Use when fetching binary data
//	NSData *responseData = [request responseData];
}

- (void)requestFailed:(ASIHTTPRequest *)request{
	NSError *error = [request error];
}


/*
 Image Content Property array
 0<property name="class" type="string">Content</property>
 1<property name="class" type="string">ImageContent</property>
 2<property name="content_text" type="null"/>
 3<property name="fb_owner" type="key">tag:sfphotolog.gmail.com,2010-10-22:FacebookUser[agpzZnBob3RvbG9nchsLEgxGYWNlYm9va1VzZXIiCTY4MjQyOTgwMgw]</property>
 4<property name="geotag" type="null"/>
 5<property name="img_src" type="key">tag:sfphotolog.gmail.com,2010-10-22:ImageBlob[agpzZnBob3RvbG9ncg8LEglJbWFnZUJsb2IYAww]</property>
 6<property name="ip_addr" type="string">127.0.0.1</property>
 7<property name="iszombie" type="bool">False</property>
 8<property name="owner" type="null"/>
 9<property name="rate" type="null"/>
 10<property name="timestamp" type="gd:when">2010-10-22 04:26:14.502870</property>
 11<property name="title" type="null"/>
 
 */
/*
 Flickr Content Property array
 0<property name="class" type="string">Content</property>
 1<property name="class" type="string">FlickrContent</property>
 2<property name="content_text" type="null"/>
 3<property name="fb_owner" type="key">tag:sfphotolog.gmail.com,2010-10-23:FacebookUser[agpzZnBob3RvbG9nchsLEgxGYWNlYm9va1VzZXIiCTY4MjQyOTgwMgw]</property>
 4<property name="geotag" type="null"/>
 5<property name="ip_addr" type="string">127.0.0.1</property>
 6<property name="iszombie" type="bool">False</property>
 7<property name="owner" type="null"/>
 8<property name="photo_id" type="string">3935285626</property>
 9<property name="rate" type="null"/>
 10<property name="real_author" type="string">Jaehong Park</property>
 11<property name="secret" type="string">7d5253c1e4</property>
 12<property name="server" type="string">2519</property>
 13<property name="tags" type="atom:category"><category label="newyork" term="user-tag"/></property>
 14<property name="tags" type="atom:category"><category label="usa" term="user-tag"/></property>
 15<property name="tags" type="atom:category"><category label="museum" term="user-tag"/></property>
 16<property name="tags" type="atom:category"><category label="people" term="user-tag"/></property>
 17<property name="timestamp" type="gd:when">2010-10-23 03:35:10.656751</property>
 18<property name="title" type="string">Appreciation</property>
 19<property name="user_id" type="string">63762119@N00</property>
 20<property name="user_name" type="string">ShorelineRunner</property>
 */

/*
 Picasa Content Property array
 0<property name="class" type="string">Content</property>
 1<property name="class" type="string">PicasaContent</property>
 2<property name="content_text" type="null"/>
 3<property name="credit" type="string">PSALTY</property>
 4<property name="fb_owner" type="key">tag:sfphotolog.gmail.com,2010-10-23:FacebookUser[agpzZnBob3RvbG9nchsLEgxGYWNlYm9va1VzZXIiCTY4MjQyOTgwMgw]</property>
 5<property name="geotag" type="null"/>
 6<property name="ip_addr" type="string">127.0.0.1</property>
 7<property name="iszombie" type="bool">False</property>
 8<property name="owner" type="null"/>
 9<property name="photo_path" type="atom:link"><link href="http://lh4.ggpht.com/_977sfzamgaE/RJvkeNUwABI/AAAAAAAAAAo/v6leWigqBHQ/ir_02.jpg"/></property>
 10<property name="rate" type="null"/>
 11<property name="thumb_large" type="null"/>
 12<property name="thumb_medium" type="atom:link"><link href="http://lh4.ggpht.com/_977sfzamgaE/RJvkeNUwABI/AAAAAAAAAAo/v6leWigqBHQ/s320/ir_02.jpg"/></property>
 13<property name="thumb_small" type="atom:link"><link href="http://lh4.ggpht.com/_977sfzamgaE/RJvkeNUwABI/AAAAAAAAAAo/v6leWigqBHQ/s72-c/ir_02.jpg"/></property>
 14<property name="timestamp" type="gd:when">2010-10-23 03:40:57.191389</property>
 15<property name="title" type="string">ir_02.jpg</property>
 
 
 */
- (void)parseGData:(NSString *)strXml{
	NSError *error;
	NSArray *entities;
	NSString *attribute;
	GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithXMLString:strXml options:0 error:&error];
    if (doc == nil){ 
		return;
	}
	
	entities = [doc.rootElement elementsForName:@"entity"];
	for(GDataXMLElement *entity in entities) 
	{
		Content *content;
		NSArray *properties	= [entity elementsForName:@"property"];
		NSString *classType = [(GDataXMLElement *)[properties objectAtIndex:1] stringValue];
		if([classType isEqualToString:@"ImageContent"]){
			content = [[ImageContent alloc] init];
		}
		else if([classType isEqualToString:@"FlickrContent"]){
			content = [[FlickrContent alloc] init];
		}
		else if([classType isEqualToString:@"PicasaContent"]){
			content = [[PicasaContent alloc] init];
		}
		else {
			return;
		}
		for(GDataXMLElement *property in properties)
		{
			attribute = [[property attributeForName:@"name"] stringValue];
			if([attribute isEqualToString:@"content_text"]){
				[content setText:[property stringValue]]; 
			}else if([attribute isEqualToString:@"img_src"]){
				[content setBlob_key:[RootViewController extractKeyValueFromXmlElement:property]];
			}else if([attribute isEqualToString:@"fb_owner"]){
				[content setOwner:[property stringValue]];
			}else if ([attribute isEqualToString:@"title"]){
				if([[property stringValue]  isEqualToString:@""])
					[content setTitle:@"Untitled"];
				else
					[content setTitle:[property stringValue]];
			}else if([attribute isEqualToString:@"photo_id"]){
				[content setPhoto_id:[property stringValue]];
			}else if ([attribute isEqualToString:@"secret"]){
				[content setSecret:[property stringValue]];
			}else if([attribute isEqualToString:@"server"]){
				[content setServer:[property stringValue]];
			}else if ([attribute isEqualToString:@"photo_path"]){
				[content setPhoto_path:[property stringValue]];
			}else if ([attribute isEqualToString:@"thumb_small"]){
				[content setThumb_s:[property stringValue]];
			}else if([attribute isEqualToString:@"thumb_medium"]){
				[content setThumb_m:[property stringValue]];
			}else if ([attribute isEqualToString:@"thumb_large"]){
				[content setThumb_l:[property stringValue]];
			}else if ([attribute isEqualToString:@"credit"]){
				[content setCredit:[property stringValue]];
			}else {
				continue;
			}
		}
		if([content respondsToSelector:@selector(thumb_medium)])
		{
			// bad implementation. need to improve here.
			NSData *rdata			= [[NSData alloc] initWithContentsOfURL:[content thumb_medium]];
			content.thumb_med		= [[UIImage alloc] initWithData:rdata];
		}
		
		[channel addObject:content];
	}
    [doc release];	
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
	
	NSArray *visibleCells = [self.tableView visibleCells];
	for(UITableViewCell *aCell in visibleCells)
	{
		[aCell deleteSubView:self];
	}

}

-(void) fbDidLogin {
	NSLog(@"logged in");
	[facebook requestWithGraphPath:@"me" andDelegate:self];
	/*
	PhotoSrcViewController *photo_source = [[PhotoSrcViewController alloc] initWithNibName:@"PhotoSrcViewController" bundle:[NSBundle mainBundle]];
	photo_source.delegate = self;
	self.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:photo_source animated:YES];
	 */
}

/**
 * Callback for facebook did not login
 */
- (void)fbDidNotLogin:(BOOL)cancelled {
	NSLog(@"did not login");
}

/**
 * Callback for facebook logout
 */
-(void) fbDidLogout {
	NSLog(@"Please Log in");

}


///////////////////////////////////////////////////////////////////////////////////////////////////
// FBRequestDelegate

/**
 * Callback when a request receives Response
 */
- (void)request:(FBRequest*)request didReceiveResponse:(NSURLResponse*)response{

	NSString *q = [response.URL absoluteString];
	//[self getStringFromUrl:q needle:@"access_token="];
	self.access_token = (NSString *)[self getStringFromUrl:q needle:@"access_token="];
	NSLog(access_token);

};

/**
 * Called when an error prevents the request from completing successfully.
 */
- (void)request:(FBRequest*)request didFailWithError:(NSError*)error{
		NSLog(@"Error");
};
/**
 * Called when a request returns and its response has been parsed into an object.
 * The resulting object may be a dictionary, an array, a string, or a number, depending
 * on thee format of the API response.
 */
- (void)request:(FBRequest*)request didLoad:(id)result {
	self.user_id = (NSString *)[result objectForKey:@"id"];
	PhotoSrcViewController *photo_source = [[PhotoSrcViewController alloc] initWithNibName:@"PhotoSrcViewController" bundle:[NSBundle mainBundle]];
	photo_source.delegate = self;
	self.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:photo_source animated:YES];
};

- (NSString *) getStringFromUrl: (NSString*) url needle:(NSString *) needle{
	NSString * str = nil;
	NSRange start = [url rangeOfString:needle];
	if (start.location != NSNotFound) {
		NSRange end = [[url substringFromIndex:start.location+start.length] rangeOfString:@"&"];
		NSUInteger offset = start.location+start.length;
		str = end.location == NSNotFound
		? [url substringFromIndex:offset]
		: [url substringWithRange:NSMakeRange(offset, end.location)];  
		str = [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
	}
	
	return str;
}

-(UIImage *)resizeImage:(UIImage *)image {
	
	CGImageRef imageRef = [image CGImage];
	CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
	CGColorSpaceRef colorSpaceInfo = CGColorSpaceCreateDeviceRGB();
	
	if (alphaInfo == kCGImageAlphaNone)
		alphaInfo = kCGImageAlphaNoneSkipLast;
	
	int width, height;
	
	width = 640;
	height = 480;
	
	CGContextRef bitmap;
	
	if (image.imageOrientation == UIImageOrientationUp | image.imageOrientation == UIImageOrientationDown) {
		bitmap = CGBitmapContextCreate(NULL, width, height, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, alphaInfo);
		
	} else {
		bitmap = CGBitmapContextCreate(NULL, height, width, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, alphaInfo);
		
	}
	
	if (image.imageOrientation == UIImageOrientationLeft) {
		NSLog(@"image orientation left");
		CGContextRotateCTM (bitmap, radians(90));
		CGContextTranslateCTM (bitmap, 0, -height);
		
	} else if (image.imageOrientation == UIImageOrientationRight) {
		NSLog(@"image orientation right");
		CGContextRotateCTM (bitmap, radians(-90));
		CGContextTranslateCTM (bitmap, -width, 0);
		
	} else if (image.imageOrientation == UIImageOrientationUp) {
		NSLog(@"image orientation up");	
		
	} else if (image.imageOrientation == UIImageOrientationDown) {
		NSLog(@"image orientation down");	
		CGContextTranslateCTM (bitmap, width,height);
		CGContextRotateCTM (bitmap, radians(-180.));
		
	}
	
	CGContextDrawImage(bitmap, CGRectMake(0, 0, width, height), imageRef);
	CGImageRef ref = CGBitmapContextCreateImage(bitmap);
	UIImage *result = [UIImage imageWithCGImage:ref];
	
	CGContextRelease(bitmap);
	CGImageRelease(ref);
	
	return result;	
}
@end

