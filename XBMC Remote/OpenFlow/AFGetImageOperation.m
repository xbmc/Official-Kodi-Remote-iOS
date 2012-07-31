/**
 * Copyright (c) 2009 Alex Fajkowski, Apparent Logic LLC
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */
#import "AFGetImageOperation.h"
#import "UIImageExtras.h"


@implementation AFGetImageOperation

- (id)initWithIndex:(int)imageIndex dataobj:(NSDictionary *)dictResult total:(int)tot viewController:(inLombardiaViewController *)viewController {
    if ((self = [super init])) {
		photoIndex = imageIndex;
        dictItems = dictResult;
		mainViewController = [viewController retain];
        total=tot;
    }
    return self;
}

- (void)dealloc {
	[mainViewController release];
    [super dealloc];
}

-(UIImage *)addText:(UIImage *)img items:(NSDictionary *)dictItem{
    //return img;
    int w = img.size.width;
    int h = img.size.height; 
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage);
    
    int font_size=13;
    int x=49;
    int deltay=131;
    int y= deltay - 2;
    NSString *denom = [[[NSString alloc] init]autorelease];
    if (((NSNull *)[dictItem objectForKey:@"DENOM"] != [NSNull null])){
        denom=[dictItem objectForKey:@"DENOM"];
    }
    else
        denom = @"non disponibile";
    NSString *POINumber=[NSString stringWithFormat:@"%d/", photoIndex + 1];
    
    NSString *poiPROV = [dictItem objectForKey:@"PROV"];
    NSString *poiAddress = [dictItem objectForKey:@"INDIRIZZO"];
    NSString *poiCOMUNE = [dictItem objectForKey:@"COMUNE"];
    NSString *poiCAP = [dictItem objectForKey:@"CAP"];
    NSString *indirizzo = [NSString stringWithFormat:@"%@%@%@%@",
                           ([poiAddress isEqualToString:@" "]) ? @"Indirizzo non disponibile" : [NSString stringWithFormat:@"%@", poiAddress],
                           ([poiCOMUNE isEqualToString:@" "]) ? @"" : [NSString stringWithFormat:@" - %@", poiCOMUNE],
                           ([poiPROV isEqualToString:@" "]) ? @"" : [NSString stringWithFormat:@" (%@)", poiPROV],
                           ([poiCAP isEqualToString:@" "]) ? @"" : [NSString stringWithFormat:@" CAP: %@",poiCAP]
                           ];
    
    //UIImage *picPOIType = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[[arrayQuickResults objectAtIndex:row] objectForKey:@"PHOTOGALLERY"]]]];
    //poiPic.image = picPOIType;
    UIImage *picPOIType= [[UIImage alloc] init];
    NSMutableString *fontName=[[NSMutableString alloc] init];
    fontName=(NSMutableString *)@"Helvetica-Bold";
    NSMutableString *fontNameDenom=[[NSMutableString alloc] init];
    fontNameDenom=(NSMutableString *)@"Helvetica-Bold";
    //NSString
    if ([[dictItem objectForKey:@"poiName"] isEqualToString:@"FarmaciaDiTurno"]) {
        NSString *imageName = [[NSString alloc] initWithFormat:@"cartello_ipad.png"];
        picPOIType = [UIImage imageNamed:imageName];
        if (picPOIType.size.width){
            CGContextDrawImage(context, CGRectMake(165, deltay - 129, picPOIType.size.width, picPOIType.size.height), picPOIType.CGImage);
        }
        
    }
    
    if ([[dictItem objectForKey:@"poiName"] isEqualToString:@"Tweet"]) {
        NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        NSString *imageName=[NSString stringWithFormat:@"%@/%@", docDir, [dictItem objectForKey:@"PHOTOGALLERY"]];
        picPOIType = [UIImage imageWithContentsOfFile:imageName];
        //picPOIType = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[dictItem objectForKey:@"PHOTOGALLERY"]]]];
        fontName=(NSMutableString *)@"Georgia";
        fontNameDenom=(NSMutableString *)@"Georgia-Bold";
        UIImage *picTweet= [[UIImage alloc] init];
        picTweet = [UIImage imageNamed:@"tweet.png"];
        if (picTweet.size.width){
            CGContextDrawImage(context, CGRectMake(190, deltay - 112, picTweet.size.width, picTweet.size.height), picTweet.CGImage);
        }
    }
    else{
        NSString *imageName = [[NSString alloc] initWithFormat:@"%@.png", [dictItem objectForKey:@"poiName"]];
        picPOIType = [UIImage imageNamed:imageName];
    }
    if (picPOIType.size.width)
        CGContextDrawImage(context, CGRectMake(7,57, picPOIType.size.width, picPOIType.size.height), picPOIType.CGImage);
    
    CGContextSetTextDrawingMode(context, kCGTextFill);
    //[picPOIType autorelease];
    denom=[denom truncateToSize:CGSizeMake(202, 23) withFont:[UIFont fontWithName:fontNameDenom size:font_size] lineBreakMode:UILineBreakModeTailTruncation];
    char* text	= (char *)[denom cStringUsingEncoding:NSMacOSRomanStringEncoding];
    CGContextSelectFont(context, (char *)[fontNameDenom cStringUsingEncoding:NSMacOSRomanStringEncoding], font_size, kCGEncodingMacRoman);
    CGContextSetRGBFillColor(context, 0, 0, 0, 0.95);
    CGContextShowTextAtPoint(context, x+1, y-1, text, strlen(text));
    CGContextSetRGBFillColor(context, 1, 1, 1, 0.95);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    font_size = 12;
    text = (char *)[[NSString stringWithFormat:@"%d", total] cStringUsingEncoding:NSMacOSRomanStringEncoding];
    x=x-21;
    CGContextSelectFont(context, (char *)[@"HelveticaNeue-BoldItalic" cStringUsingEncoding:NSMacOSRomanStringEncoding], font_size, kCGEncodingMacRoman);
    CGContextSetRGBFillColor(context, 0, 0, 0, 0.60);
    CGContextShowTextAtPoint(context, x+1, y-1, text, strlen(text));
    CGContextSetRGBFillColor(context, 1, 1, 1, 0.60);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    
    font_size=14;
    text = (char *)[POINumber cStringUsingEncoding:NSMacOSRomanStringEncoding];
    int delta=[POINumber sizeWithFont: [UIFont fontWithName:@"HelveticaNeue-Bold" size:font_size]].width;
     x= 28 - delta;
    CGContextSelectFont(context, (char *)[@"HelveticaNeue-BoldItalic" cStringUsingEncoding:NSMacOSRomanStringEncoding], font_size, kCGEncodingMacRoman);
    CGContextSetRGBFillColor(context, 0, 0, 0, 0.60);
    CGContextShowTextAtPoint(context, x+1, y-1, text, strlen(text));
    CGContextSetRGBFillColor(context, 1, 1, 1, 0.60);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    font_size=12;
    x=60;
    y= deltay - 37 ;
    int num_line=3;
    if ([fontName isEqualToString:@"Georgia"]){
        font_size=13;
    }
    while (num_line && ![indirizzo isEqualToString:@""]){
        
        NSString *part_indirizzo=[indirizzo truncateToSize:CGSizeMake(174, 23) withFont:[UIFont fontWithName:fontName size:font_size] lineBreakMode:UILineBreakModeWordWrap];
        text = (char *)[part_indirizzo cStringUsingEncoding:NSMacOSRomanStringEncoding];
        CGContextSelectFont(context, (char *)[fontName cStringUsingEncoding:NSMacOSRomanStringEncoding], font_size, kCGEncodingMacRoman);
        CGContextSetRGBFillColor(context, 0, 0, 0, 1);
        CGContextShowTextAtPoint(context, x, y, text, strlen(text));
        indirizzo = [indirizzo stringByReplacingOccurrencesOfString:part_indirizzo withString:@""];
        num_line--;
        y-=15;
    }
    
    if (![[dictItem objectForKey:@"distanceSTR"] isEqualToString:@""]){
        NSString *tvDistance = [NSString stringWithFormat:@"%@ Km", [dictItem objectForKey:@"distanceSTR"]];
        NSString *distanceLabel=@"distanza:";
        x=52;
        y=deltay - 94;
        text	= (char *)[distanceLabel cStringUsingEncoding:NSMacOSRomanStringEncoding];
        CGContextSelectFont(context, (char *)[@"Helvetica-Oblique" cStringUsingEncoding:NSMacOSRomanStringEncoding], font_size, kCGEncodingMacRoman);
        CGContextSetRGBFillColor(context, 0, 0, 0, 1);
        CGContextShowTextAtPoint(context, x, y, text, strlen(text));
        
        x=108;
        y=deltay - 94;
        text	= (char *)[tvDistance cStringUsingEncoding:NSMacOSRomanStringEncoding];
        CGContextSelectFont(context, (char *)[@"Helvetica-Bold" cStringUsingEncoding:NSMacOSRomanStringEncoding], font_size, kCGEncodingMacRoman);
        CGContextSetRGBFillColor(context, 0, 0, 0, 1);
        CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    }
    if ([[dictItem objectForKey:@"poiName"] isEqualToString:@"Tweet"]) {
        x=52;
        y=deltay - 94;
        text	= (char *)[[dictItem objectForKey:@"INSEGNA"] cStringUsingEncoding:NSMacOSRomanStringEncoding];
        CGContextSelectFont(context, (char *)[@"Helvetica-Oblique" cStringUsingEncoding:NSMacOSRomanStringEncoding], font_size, kCGEncodingMacRoman);
        CGContextSetRGBFillColor(context, 0, 0, 0, 1);
        CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    }
    x=199;
    y=deltay-113;
    NSString *poiName = [dictItem objectForKey:@"poiName"];
    if ([poiName isEqualToString:@"TassaAuto"]){
        NSString *picTipologia = [NSString stringWithFormat:@"%@.gif",[dictItem objectForKey:@"TIPOLOGIAID"]];
        UIImage *imgTipologia = [UIImage imageNamed:picTipologia];
        if (imgTipologia.size.width)
            CGContextDrawImage(context, CGRectMake(x, y, imgTipologia.size.width, imgTipologia.size.height), imgTipologia.CGImage);
        
        x=175;
        NSString *picBrand = [NSString stringWithFormat:@"%@.gif",[dictItem objectForKey:@"BRANDID"]];
        UIImage *imgBrand = [UIImage imageNamed:picBrand];
        if (imgBrand.size.width)
            CGContextDrawImage(context, CGRectMake(x, y, imgBrand.size.width, imgBrand.size.height), imgBrand.CGImage);
        
        x=222;
        NSString *picServizio = [NSString stringWithFormat:@"%@.gif",[dictItem objectForKey:@"SERVIZIOID"]];
        UIImage *imgServizio = [UIImage imageNamed:picServizio];
        if (imgServizio.size.width)
            CGContextDrawImage(context, CGRectMake(x, y, imgServizio.size.width, imgServizio.size.height), imgServizio.CGImage);
    }

    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
	//[picPOIType release];
    img=[UIImage imageWithCGImage:imageMasked];
    CGImageRelease(imageMasked);
    [fontName release];
    [fontNameDenom release];
    //[denom release];
    return img;
}

- (void)main {
    NSString *imageName = [[NSString alloc] initWithFormat:@"bargreen_img.png", photoIndex];
    UIImage *theImage = [UIImage imageNamed:imageName];
    theImage = [self addText:theImage items:dictItems];
    
    if (theImage) {
        [mainViewController performSelectorOnMainThread:@selector(imageDidLoad:) 
                                             withObject:[NSArray arrayWithObjects:theImage, [NSNumber numberWithInt:photoIndex], nil] 
                                          waitUntilDone:YES];
    } else
        //NSLog(@"impossibile trovare l'immagine: %@", imageName);
    [imageName release];
    
}
	
//	[pool release];
//}

@end