//
//  HelloWorldLayer.h
//  CocosDistort
//
//  Created by Ferrari Pierre on 19.04.11.
//  Copyright piferrari.org 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "CCTouchDispatcher.h"
#import "SimpleAudioEngine.h"

#define GRID_SIZE_X  32
#define GRID_SIZE_Y  32
#define CLIP_NEAR  (-1024 * CC_CONTENT_SCALE_FACTOR())
#define CLIP_FAR   (1024 * CC_CONTENT_SCALE_FACTOR())
#define SPRING_KS  0.3
#define DRAG	   0.5
#define THRESHOLD 2.0

typedef struct {
  float x[3];
  float v[3];
  float t[2];
  int nail;
} MASS;

typedef struct {
  int i, j;
  float r;
} SPRING;

// HelloWorldLayer
@interface CocosDistort : CCLayer <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIAccelerometerDelegate>
{
  CCTexture2D *texture2D;
  int grab;
  int spring_count;
  MASS *mass;
  SPRING *spring;
  GLushort indices[ GRID_SIZE_X * GRID_SIZE_Y * 6 ];
  float mousex;
  float mousey;
  ALuint sound;
  ALuint elastic;
  UIImage *originalImage;
  BOOL shake;
  BOOL isTakeImage;
}

@property (nonatomic, retain) CCTexture2D *texture2D;
@property (nonatomic, readwrite) int grab;
@property (nonatomic, readwrite) int spring_count;
@property (nonatomic, readwrite) MASS *mass;
@property (nonatomic, readwrite) SPRING *spring;
@property (nonatomic, readwrite) float mousex;
@property (nonatomic, readwrite) float mousey;
@property (readwrite) ALuint sound;
@property (readwrite) ALuint elastic;
@property (nonatomic, retain) UIImage *originalImage;
@property (readwrite) BOOL shake;
@property (readwrite) BOOL isTakeImage;

+(CCScene *) scene;
- (void)rubber_redraw;
- (int)rubber_grab:(int)x:(int)y;
- (void)rubber_init;
- (void)rubber_dynamics:(int)x:(int)y;
- (void)takeImage;
- (UIImage *)scaleAndRotateImage:(UIImage *)image;
- (UIImage *)centerScreen:(UIImage *)image;
- (void)orientationChanged;


@end
