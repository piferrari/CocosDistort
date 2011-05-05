//
//  HelloWorldLayer.m
//  CocosDistort
//
//  Created by Ferrari Pierre on 19.04.11.
//  Copyright piferrari.org 2011. All rights reserved.
//

#import "AppDelegate.h"

// Import the interfaces
#import "CocosDistort.h"

// HelloWorldLayer implementation
@implementation CocosDistort

@synthesize texture2D, grab, spring_count, mass, spring, mousex, mousey, sound, elastic, originalImage, shake, pickerVisible;

+ (CCScene *)scene {
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	CocosDistort *layer = [CocosDistort node];
	
	// add layer as a child to scene
	[scene addChild: layer];
  	
	// return the scene
	return scene;
}

- (id)init {
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"touk.wav"];
    self.isAccelerometerEnabled = YES;
    [[UIAccelerometer sharedAccelerometer] setDelegate:self];
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:1/60];
    shake = NO;
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
    [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
    originalImage = [UIImage imageNamed:@"distort.png"];
    texture2D = [[CCTexture2D alloc] initWithImage:originalImage];
    [self rubber_init];
    [self scheduleUpdateWithPriority:-1];
    self.isTouchEnabled = YES;
    pickerVisible = NO;
	}
	return self;
}

- (void)draw {
	glDisableClientState(GL_COLOR_ARRAY);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glColor4ub(224,224,244,200);

  [self rubber_redraw];
  
  glBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);
	glEnableClientState(GL_COLOR_ARRAY);
}

- (void)update:(ccTime)deltaTime {
  [self rubber_dynamics:mousex:mousey];
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration  {
  if (acceleration.x > THRESHOLD || acceleration.x < -THRESHOLD || 
      acceleration.y > THRESHOLD || acceleration.y < -THRESHOLD ||
      acceleration.z > THRESHOLD || acceleration.z < -THRESHOLD) {
    if (!shake) {
      shake = YES;
      [self takeImage];
    }
  }
  else {
    shake = NO;
  }
}

- (void)orientationChanged {
  if (pickerVisible == NO) {
    [[CCDirector sharedDirector] pause];
    [[CCDirector sharedDirector] stopAnimation];
    
    UIImage *rotateImage = [self scaleAndRotateImage:originalImage];
    UIImage *final = [self centerScreen:rotateImage];
    [texture2D release];
    texture2D = [[CCTexture2D alloc] initWithImage:final];
    
    [[CCDirector sharedDirector] resume];
    [[CCDirector sharedDirector] startAnimation];
    NSLog(@"Orientation change");
  }
}

- (UIImage *)centerScreen:(UIImage *)image {
  CGImageRef imgRef = image.CGImage;
  
  CGAffineTransform transform = CGAffineTransformIdentity;
  CGRect bounds = [[[CCDirector sharedDirector] openGLView] frame];//[[UIScreen mainScreen] bounds];
  
  NSLog(@"bounds -> width:%f height:%f", bounds.size.width, bounds.size.height);
  
  UIGraphicsBeginImageContext(bounds.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGContextTranslateCTM(context, 0.0, bounds.size.height); //i.e., move the y-origin from the top to the bottom
  CGContextScaleCTM(context, 1.0, -1.0); //i.e., invert the y-axis        
  CGContextConcatCTM(context, transform);
  CGContextDrawImage(UIGraphicsGetCurrentContext(), bounds, imgRef);
  UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return imageCopy;
}

- (UIImage *)scaleAndRotateImage:(UIImage *)image {
  int kMaxResolution = 320; //640
  
  CGImageRef imgRef = image.CGImage;
  
  CGFloat width = CGImageGetWidth(imgRef);
  CGFloat height = CGImageGetHeight(imgRef);
  
  CGAffineTransform transform = CGAffineTransformIdentity;
  CGRect bounds = CGRectMake(0, 0, width, height);
  if (width > kMaxResolution || height > kMaxResolution) {
    CGFloat ratio = width/height;
    if (ratio > 1) {
      bounds.size.width = kMaxResolution;
      bounds.size.height = bounds.size.width / ratio;
    }
    else {
      bounds.size.height = kMaxResolution;
      bounds.size.width = bounds.size.height * ratio;
    }
  }
  
  CGFloat scaleRatio = bounds.size.width / width;
  CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
  CGFloat boundHeight;
  UIImageOrientation orient = image.imageOrientation;
  switch(orient) {
      
    case UIImageOrientationUp: //EXIF = 1
      transform = CGAffineTransformIdentity;
      break;
      
    case UIImageOrientationUpMirrored: //EXIF = 2
      transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
      transform = CGAffineTransformScale(transform, -1.0, 1.0);
      break;
      
    case UIImageOrientationDown: //EXIF = 3
      transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
      transform = CGAffineTransformRotate(transform, M_PI);
      break;
      
    case UIImageOrientationDownMirrored: //EXIF = 4
      transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
      transform = CGAffineTransformScale(transform, 1.0, -1.0);
      break;
      
    case UIImageOrientationLeftMirrored: //EXIF = 5
      boundHeight = bounds.size.height;
      bounds.size.height = bounds.size.width;
      bounds.size.width = boundHeight;
      transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
      transform = CGAffineTransformScale(transform, -1.0, 1.0);
      transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
      break;
      
    case UIImageOrientationLeft: //EXIF = 6
      boundHeight = bounds.size.height;
      bounds.size.height = bounds.size.width;
      bounds.size.width = boundHeight;
      transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
      transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
      break;
      
    case UIImageOrientationRightMirrored: //EXIF = 7
      boundHeight = bounds.size.height;
      bounds.size.height = bounds.size.width;
      bounds.size.width = boundHeight;
      transform = CGAffineTransformMakeScale(-1.0, 1.0);
      transform = CGAffineTransformRotate(transform, M_PI / 2.0);
      break;
      
    case UIImageOrientationRight: //EXIF = 8
      boundHeight = bounds.size.height;
      bounds.size.height = bounds.size.width;
      bounds.size.width = boundHeight;
      transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
      transform = CGAffineTransformRotate(transform, M_PI / 2.0);
      break;
      
    default:
      [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
      
  }
  
  UIGraphicsBeginImageContext(bounds.size);
  
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
    CGContextScaleCTM(context, -scaleRatio, scaleRatio);
    CGContextTranslateCTM(context, -height, 0);
  }
  else {
    CGContextScaleCTM(context, scaleRatio, -scaleRatio);
    CGContextTranslateCTM(context, 0, -height);
  }
  
  CGContextConcatCTM(context, transform);
  
  CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
  UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return imageCopy;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  BOOL show = YES;
  AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  UIImagePickerController *picker = nil;
	picker = [[UIImagePickerController alloc] init];
  picker.delegate = self;
  picker.wantsFullScreenLayout = YES;
  picker.allowsEditing = NO;
  
  NSLog(@"%i", [actionSheet numberOfButtons]);
  if ([actionSheet numberOfButtons] == 3) {
    switch (buttonIndex) {
      case 0:
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        break;
      case 1:
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        break;
      case 2:
        show = NO;
        break;
    }
  }
  
  if ([actionSheet numberOfButtons] == 2) {
    switch (buttonIndex) {
      case 0:
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        break;
      case 1:
        show = NO;
        break;
    }
  }
  
  if (show) {
    [delegate.viewController presentModalViewController:picker animated:YES];
    [[[CCDirector sharedDirector] openGLView] addSubview:picker.view];
    pickerVisible = YES;
  }
  else {
    [picker release];
    [[CCDirector sharedDirector] resume];
    [[CCDirector sharedDirector] startAnimation];
  }
}

- (void)takeImage {
  [[CCDirector sharedDirector] pause];
  [[CCDirector sharedDirector] stopAnimation];
  UIActionSheet *actionSheet = nil;
  
  if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] &&
     [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
  {
    actionSheet = [[UIActionSheet alloc] initWithTitle:@"Take picture from" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Photo library", @"Camera", nil];    
  }
  else if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
  {
    actionSheet = [[UIActionSheet alloc] initWithTitle:@"Take picture from" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Photo library", nil]; 
  }
  
  if (actionSheet != nil) {
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:[[CCDirector sharedDirector] openGLView]];
    [actionSheet release];
  }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  [originalImage release];
  originalImage = [[info objectForKey:@"UIImagePickerControllerOriginalImage"] retain];
  UIImage *rotateImage = [self scaleAndRotateImage:originalImage];
  UIImage *final = [self centerScreen:rotateImage];
  [texture2D release];
  texture2D = [[CCTexture2D alloc] initWithImage:final];
  
  NSLog(@"picker -> rotateImageW:%f rotateImageH:%f texture2DW:%f texture2DH:%f", [rotateImage size].width, [rotateImage size].height, texture2D.contentSizeInPixels.width, texture2D.contentSizeInPixels.height);

	[picker dismissModalViewControllerAnimated:YES];
	[picker.view removeFromSuperview];
  [picker release];
  pickerVisible = NO;
  
  [[CCDirector sharedDirector] resume];
  [[CCDirector sharedDirector] startAnimation];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissModalViewControllerAnimated:YES];
	[picker.view removeFromSuperview];
  [picker release];
  pickerVisible = NO;
  [[CCDirector sharedDirector] resume];
  [[CCDirector sharedDirector] startAnimation];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
//  if (touch.tapCount == 2) {
//    [self takeImage];
//  }
  CGPoint location = [self convertTouchToNodeSpace: touch];
  mousex = location.x;
  mousey = location.y;
  NSLog(@"TouchBegan -> mousex:%f mousey:%f", mousex, mousey);

  grab = [self rubber_grab:location.x:location.y];
  
  elastic = 0;
  sound = [[SimpleAudioEngine sharedEngine] playEffect:@"touk.wav"];

  return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
  CGPoint location = [self convertTouchToNodeSpace: touch];
  mousex = location.x;
  mousey = location.y;
  NSLog(@"TouchMoved -> mousex:%f mousey:%f", mousex, mousey);
  
  if (!elastic) {
    elastic = [[SimpleAudioEngine sharedEngine] playEffect:@"elastic.wav"];
  }

}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
	grab = -1;
  if (sound) {
    [[SimpleAudioEngine sharedEngine] stopEffect:elastic];
    sound = [[SimpleAudioEngine sharedEngine] playEffect:@"trampoline.wav"];
  }
}

- (void)dealloc {
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
  //[self unscheduleSelector:@selector(rubber_dynamics:)];
  [originalImage release];
  [[SimpleAudioEngine sharedEngine] unloadEffect:@"elastic.wav"];
  [SimpleAudioEngine end];
  [self unscheduleUpdate];
  [texture2D release];
	// don't forget to call "super dealloc"
	[super dealloc];
}

/*
 Do the dynamics simulation for the next frame.
 */
- (void)rubber_dynamics:(int)x:(int)y {
  int k;
  float d[3];
  int i, j;
  float l;
  float a;
  
  /* calculate all the spring forces acting on the mass points */
  
  for (k = 0; k < spring_count; k++)
  {
    i = spring[k].i;
    j = spring[k].j;
    
    d[0] = mass[i].x[0] - mass[j].x[0];
    d[1] = mass[i].x[1] - mass[j].x[1];
    d[2] = mass[i].x[2] - mass[j].x[2];
    
    l = sqrt(d[0]*d[0] + d[1]*d[1] + d[2]*d[2]);
    
    if (l != 0.0)
    {
      d[0] /= l;
      d[1] /= l;
      d[2] /= l;
      
      a = l - spring[k].r;
      
      mass[i].v[0] -= d[0]*a*SPRING_KS;
      mass[i].v[1] -= d[1]*a*SPRING_KS;
      mass[i].v[2] -= d[2]*a*SPRING_KS;
      
      mass[j].v[0] += d[0]*a*SPRING_KS;
      mass[j].v[1] += d[1]*a*SPRING_KS;
      mass[j].v[2] += d[2]*a*SPRING_KS;
    }
  }
  
  /* update the state of the mass points */
  
  for (k = 0; k < GRID_SIZE_X*GRID_SIZE_Y; k++)
    if (!mass[k].nail)
    {
      mass[k].x[0] += mass[k].v[0];
      mass[k].x[1] += mass[k].v[1];
      mass[k].x[2] += mass[k].v[2];
      
      mass[k].v[0] *= (1.0 - DRAG);
      mass[k].v[1] *= (1.0 - DRAG);
      mass[k].v[2] *= (1.0 - DRAG);
      
      if (mass[k].x[2] > -CLIP_NEAR - 0.01)
        mass[k].x[2] = -CLIP_NEAR - 0.01;
      if (mass[k].x[2] < -CLIP_FAR + 0.01)
        mass[k].x[2] = -CLIP_FAR + 0.01;
    }
  
  /* if a mass point is grabbed, attach it to the mouse */
  
  if (grab != -1 && !mass[grab].nail)
  {
    mass[grab].x[0] = x;
    mass[grab].x[1] = y;
    mass[grab].x[2] = -(CLIP_FAR - CLIP_NEAR)/4.0;
  }
}

/*
 Draw the next frame of animation.
 */

- (void)rubber_redraw {
  int k;
  int i, j;
  if(mass == NULL) {
    NSLog(@"mass is null");
    return;
  }
  glBindTexture(GL_TEXTURE_2D, [texture2D name]);
  
  k = 0;
  for (i = 0; i < GRID_SIZE_X - 1; i++)
  {
    for (j = 0; j < GRID_SIZE_Y - 1; j++)
    {
      GLfloat vertices[]= {
        mass[k].x[0],mass[k].x[1],mass[k].x[2], 
        mass[k + 1].x[0],mass[k + 1].x[1],mass[k + 1].x[2],
        mass[k + GRID_SIZE_Y + 1].x[0],mass[k + GRID_SIZE_Y + 1].x[1],mass[k + GRID_SIZE_Y + 1].x[2], 
        mass[k + GRID_SIZE_Y].x[0],mass[k + GRID_SIZE_Y].x[1],mass[k + GRID_SIZE_Y].x[2]
      };
      GLfloat tex[]={
        mass[k].t[0], mass[k].t[1], 
        mass[k + 1].t[0], mass[k + 1].t[1],
        mass[k + GRID_SIZE_Y + 1].t[0], mass[k + GRID_SIZE_Y + 1].t[1],
        mass[k + GRID_SIZE_Y].t[0], mass[k + GRID_SIZE_Y].t[1]
      };
      
      glVertexPointer(3, GL_FLOAT, 0, vertices);
      glTexCoordPointer(2, GL_FLOAT, 0, tex);

      glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

      k++;
    }
    k++;
  }
}

- (int)rubber_grab:(int)x:(int)y {
  float dx[2];
  float d;
  float min_d;
  float min_i;
  int i;
  
  for (i = 0; i < GRID_SIZE_X*GRID_SIZE_Y; i++)
  {
    dx[0] = mass[i].x[0] - x;
    dx[1] = mass[i].x[1] - y;
    d = sqrt(dx[0]*dx[0] + dx[1]*dx[1]);
    if (i == 0 || d < min_d)
    {
      min_i = i;
      min_d = d;
    }
  }
  
  return min_i;
}

- (void)rubber_init {
  GLint width = texture2D.contentSizeInPixels.width;
  GLint height = texture2D.contentSizeInPixels.height;
  int i, j;
  int k;
  int m;
  
  if (mass == NULL)
  {
    mass = (MASS *) malloc(sizeof(MASS)*GRID_SIZE_X*GRID_SIZE_Y);
    if (mass == NULL)
    {
      fprintf(stderr, "rubber: Can't allocate memory.\n");	
      exit(-1);
    }
  }
  
  k = 0;
  for (i = 0; i < GRID_SIZE_X; i++)
    for (j = 0; j < GRID_SIZE_Y; j++)
    {
      mass[k].nail = (i == 0 || j == 0 || i == GRID_SIZE_X - 1
                      || j == GRID_SIZE_Y - 1);
      mass[k].x[0] = i/(GRID_SIZE_X - 1.0)*width;
      mass[k].x[1] = j/(GRID_SIZE_Y - 1.0)*height;
      mass[k].x[2] = -(CLIP_FAR - CLIP_NEAR)/2.0;
      
      mass[k].v[0] = 0.0;
      mass[k].v[1] = 0.0;
      mass[k].v[2] = 0.0;
      
      mass[k].t[0] = i/(GRID_SIZE_X - 1.0);
      mass[k].t[1] = j/(GRID_SIZE_Y - 1.0);
      
      k++;
    }
  
  if (spring == NULL)
  {
    spring_count = (GRID_SIZE_X - 1)*(GRID_SIZE_Y - 2)
    + (GRID_SIZE_Y - 1)*(GRID_SIZE_X - 2);
    
    spring = (SPRING *) malloc(sizeof(SPRING)*spring_count);
    if (spring == NULL)
    {
      fprintf(stderr, "rubber: Can't allocate memory.\n");	
      exit(-1);
    }
  }
  
  k = 0;
  for (i = 1; i < GRID_SIZE_X - 1; i++)
    for (j = 0; j < GRID_SIZE_Y - 1; j++)
    {
      m = GRID_SIZE_Y*i + j;
      spring[k].i = m;
      spring[k].j = m + 1;
      spring[k].r = (height - 1.0)/(GRID_SIZE_Y - 1.0);
      k++;
    }
  
  for (j = 1; j < GRID_SIZE_Y - 1; j++)
  {
    for (i = 0; i < GRID_SIZE_X - 1; i++)
    {
      m = GRID_SIZE_Y*i + j;
      spring[k].i = m;
      spring[k].j = m + GRID_SIZE_X;
      spring[k].r = (width - 1.0)/(GRID_SIZE_X - 1.0);
      k++;
    }
  }
  
  //k = 0;
	for ( i = 0; i < GRID_SIZE_Y - 1; i++ )
	{
		for ( j = 0; j < GRID_SIZE_X - 1; j++ )
		{	
			k = i * GRID_SIZE_X + j;
			indices[k * 6 + 0] = ( i     ) * GRID_SIZE_X + j;
			indices[k * 6 + 1] = ( i + 1 ) * GRID_SIZE_X + j;
			indices[k * 6 + 2] = ( i + 1 ) * GRID_SIZE_X + j + 1;
			indices[k * 6 + 3] = ( i     ) * GRID_SIZE_X + j;
			indices[k * 6 + 4] = ( i + 1 ) * GRID_SIZE_X + j + 1;
			indices[k * 6 + 5] = ( i     ) * GRID_SIZE_X + j + 1;
		}
	}
}

@end
