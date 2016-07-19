//
//  AppDelegate.swift
//  SSFW
//
//  Created by Jeff Creswell on 2015-10-30.
//  Copyright © 2015 Jeff Creswell. All rights reserved.
//  
//  This app serves as a digital photoframe for your app icon dock by setting images in the chosen directory as its app icon.  Animated gifs are supported, and there is a crude 'zoom' mechanism
//

import Cocoa

extension NSImage {
    func resizeImage(width: CGFloat, _ height: CGFloat) -> NSImage {
        let img = NSImage(size: CGSizeMake(width, height))
        
        img.lockFocus()
        let ctx = NSGraphicsContext.currentContext()
        ctx?.imageInterpolation = .High
        self.drawInRect(NSMakeRect(0, 0, width, height), fromRect: NSMakeRect(0, 0, size.width, size.height), operation: .CompositeCopy, fraction: 1)
        img.unlockFocus()
        
        return img
    }
}
extension CollectionType {
    /// Return a copy of `self` with its elements shuffled
    func shuffle() -> [Generator.Element] {
        var list = Array(self)
        list.shuffleInPlace()
        return list
    }
}

extension MutableCollectionType where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in 0..<count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var app:NSApplication = NSApplication.sharedApplication();
    var mImageCount:Int = 0;
    var mImagePointer:Int = 0;
    var mImageList = [String]();
    var mBundledImageList = [String]();//TODO: how do you get a list of bundled image sets in Swift?
    var mImageSetDir:String = "insert your favorite picture directory path here";
    var mImageIterationTimer = NSTimer();
    var mIterating:Bool = false;
    
    //controllers dedicated to what I like to call the mighty Veronica Belmont's Priestess of Cthulhu aka 'so lifelike!' gif.  I wonder if you can get DMCAed for having somebody's likeness in a silly gif without their explicit consent in a dinky little open-source project?  Guess we'll find out, 'cause I'm not taking her out without one.  
    var mSoLifeLikeTimer = NSTimer();
    var mSoLifeLikeImageRep:NSBitmapImageRep?;
    var mSoLifeLikeFrameIndex:Int = 0;
    var mIsSoLifeLike = false;
    
    //controllers for arbitrary gifs discovered in image sets
    var mAnimatedGifTimer = NSTimer();
    var mAnimatedGifImageRep:NSBitmapImageRep?;
    var mAnimatedGifFrameIndex:Int = 0;
    var mAnimatedGifFrameCount:Int = 0;
    var mAnimatedGifFrameDuration:Float = 0.0;
    var mIsAnimating = false;
    
    //TODO: implement handling of mouse scroll wheel in the control window -- have scroll up call incImage and scroll down call decImage such that we don't have to click every time
    //TODO: make the time delay for iteration configurable someplace
    //TODO: add the ability to modify frame duration of animated gifs



    func applicationDidFinishLaunching(aNotification: NSNotification) {
       
        
        listImageSet(mImageSetDir);
        
        
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func getImageSetDir()->String{
        return mImageSetDir;
    }
    func setImageSetDir(imageSetDir:String){
        mImageSetDir = imageSetDir;
    }
    func updateImageSetDir(imageSetDir:String){
        setImageSetDir(imageSetDir);
        mImageList.removeAll()
        mImageCount = 0;
        mImagePointer = 0;
        listImageSet(mImageSetDir);
        
        for Image in 0...mImageCount-1{
            print("Image number \(Image) is \(mImageList[Image])");
        }
        
    }
    
        
    /**
     Lists all the Image images in image set, and initializes the mImageCount field
     */
    func listImageSet(folderPath:String){
        let fileManager = NSFileManager.defaultManager()
        let enumerator:NSDirectoryEnumerator? = fileManager.enumeratorAtPath(folderPath)
        while let element = enumerator?.nextObject() as? String {
            let image:String = element.lowercaseString;//normalize as lowercase to make analysis (just file extension here) simpler
            if image.hasSuffix("jpg") || image.hasSuffix("png") || image.hasSuffix("jpeg") || image.hasSuffix("gif") { // checks the extension
                NSLog("discovered image "+element);
                mImageList.append(element);//note the return to using element rather than image, since we need case to be preserved for the file names
                mImageCount++;
                
            }
        }
    }
    
    /**
     Randomizes the image set order
    */
    func randImageSet(){
        
        if(mImageList.count > 0){
            mImageList = mImageList.shuffle();
        }else{
            print("you've no images to randomize!  Select an image set dir");
        }
    }
    
    
    
    func getBundledImage(imageSetName:String)->NSImage{
        
        var newIcon:NSImage = NSImage(named:imageSetName)!
        //resizing experiments to see how much of a bro NSImage is wrt scaling UPDATE: not very much of a bro at all, it seems.
        let origSize:NSSize = newIcon.size;
        
        print("image orig dimens are: \(origSize.width),\(origSize.height)");
        newIcon = resize(newIcon,w: Int(origSize.width),h: Int(origSize.height));
        return newIcon;
        
        
    }
    
    func doZoom(coefficients:[CGFloat]){
        //take the coefficient array from viewcontroller and calculate the srcRect we want to be the fromRect in NSMakeRect
        
        
        var srcRectArgs:[CGFloat] = [CGFloat]();
        let imgSize:NSSize = app.applicationIconImage.size;
        print("icon image size is \(imgSize.width),\(imgSize.height)");
       
        srcRectArgs.append(coefficients[0] * imgSize.width);
        srcRectArgs.append(coefficients[1] * imgSize.height);
        srcRectArgs.append(coefficients[2] * imgSize.width);
        srcRectArgs.append(coefficients[3] * imgSize.height);

        //todox: the 'dstRect' (first arg to drawInRect in resize) shouldn't be the original image size; if it is, you'll get scaling quality loss in the final
        // resized image because the srcRect is almost always significantly smaller than the whole image [else why would we want to zoom].  If it is and the aspect ratio of the srcRect is significantly different from the original image, you'll get scaling loss and warping.
        //UDPATE: in my experience, this issue doesn't actually matter because the image has to be sized to the app icon anyway, and never actually gets to be dstRect dimensions.  One would expect this to lead to lossy scaling all the same though since you'd expect the operations to be crop to srcRect->scale to fit dstRect->scale again to fit app icon rect, but for whatever reason the final image in the app icon looks to me like it went directly crop to srcRect->scale fit app icon rect.  
        //todo: figure out why this works
        app.applicationIconImage = resize(app.applicationIconImage, w: imgSize.width, h: imgSize.height, srcRectArgs: srcRectArgs);
        
        
    }
    /**
     Expects an array of coefficients that indicate the relative x,y,width,height of the zoomed area that should be used as the src rectangle args when
     we call NSMakeRect for the fromRect arg of drawInRect in resize
    */
    
    func calculateZoomedRectArgs(coefficients:[CGFloat])->[CGFloat]{
        var srcRectArgs:[CGFloat] = [CGFloat]();
        let imgSize:NSSize = app.applicationIconImage.size;
        print("icon image size is \(imgSize.width),\(imgSize.height)");
        srcRectArgs.append(coefficients[0] * imgSize.width);
        srcRectArgs.append(coefficients[1] * imgSize.height);
        srcRectArgs.append(coefficients[2] * imgSize.width);
        srcRectArgs.append(coefficients[3] * imgSize.height);
        return srcRectArgs;

    }
    
    
    func resize(image: NSImage, w: CGFloat, h: CGFloat,srcRectArgs:[CGFloat]) -> NSImage {
        var destSize = NSMakeSize(w, h)
        var newImage = NSImage(size: destSize)
        newImage.lockFocus()
        //the fromRect param is our jam here -- it selects the rectangular subset of the source image to sample from.  If'n we want to zoom in on user selected region, this'll be the man to modify
        image.drawInRect(NSMakeRect(0, 0, destSize.width, destSize.height), fromRect: NSMakeRect(srcRectArgs[0], srcRectArgs[1], srcRectArgs[2], srcRectArgs[3]), operation: NSCompositingOperation.CompositeSourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = destSize
        return NSImage(data: newImage.TIFFRepresentation!)!
    }

    func resize(image: NSImage, w: Int, h: Int) -> NSImage {
        var destSize = NSMakeSize(CGFloat(w), CGFloat(h))
        var newImage = NSImage(size: destSize)
        newImage.lockFocus()
        //the fromRect param is our jam here -- it selects the rectangular subset of the source image to sample from.  If'n we want to zoom in on user selected region, this'll be the man to modify
        image.drawInRect(NSMakeRect(0, 0, destSize.width, destSize.height), fromRect: NSMakeRect(0, 0, image.size.width, image.size.height), operation: NSCompositingOperation.CompositeSourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = destSize
        return NSImage(data: newImage.TIFFRepresentation!)!
    }
    func resize(image: NSImage, width: CGFloat, height: CGFloat) -> NSImage {
        var destSize = NSMakeSize(width, height)
        var newImage = NSImage(size: destSize)
        newImage.lockFocus()
        //the fromRect param is our jam here -- it selects the rectangular subset of the source image to sample from.  If'n we want to zoom in on user selected region, this'll be the man to modify
        image.drawInRect(NSMakeRect(0, 0, destSize.width, destSize.height), fromRect: NSMakeRect(0, 0, image.size.width, image.size.height), operation: NSCompositingOperation.CompositeSourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = destSize
        return NSImage(data: newImage.TIFFRepresentation!)!
    }
    
    
    /**
     Watch the Cthulhu swim through the ocean -- so lifelike!
    */
    func doSoLifeLike(){
        
        mSoLifeLikeFrameIndex = 0;
        
        
        if(!mIsSoLifeLike){
            mIsSoLifeLike = true;
            var priestessPath:String = NSBundle.mainBundle().pathForResource("CthulhuPriestessData", ofType: "gif")!;
            var data = NSData.init(contentsOfFile: priestessPath);
            mSoLifeLikeImageRep = NSBitmapImageRep.init(data: data!)!;
            mSoLifeLikeTimer = NSTimer.scheduledTimerWithTimeInterval(0.06, target: self, selector: "incSoLifeLikeFrame", userInfo: nil, repeats: true)
        }
        else{
            mSoLifeLikeTimer.invalidate();
            mIsSoLifeLike = false;
        }
        
    }
    
    func incSoLifeLikeFrame(){
        if(mSoLifeLikeFrameIndex == 48){
            mSoLifeLikeFrameIndex = 0;
        }
        
        var imageRep = mSoLifeLikeImageRep!;
        imageRep.setProperty("NSImageCurrentFrame", withValue: mSoLifeLikeFrameIndex);
        var frameImage = NSImage.init();
        frameImage.addRepresentation(imageRep);
        
        
        if(ZoomViewController.getCoefficientArray().count == 4){
            frameImage = resize(frameImage, w: frameImage.size.width, h: frameImage.size.height, srcRectArgs: calculateZoomedRectArgs(ZoomViewController.getCoefficientArray()));
        }
        
        
        //TODO: this is probably a good part of why this app icon gif impl has such a horrific CPU usage -- might be better to add all the imagereps to the applicationiconimage NSImage  and then cycle through them; at least that way you'd be re-using the same NSImage object so there'd be less memory op overhead
        
        app.applicationIconImage = frameImage;
        mSoLifeLikeFrameIndex++;

    }
    
    func doAnimation(path:String){
        //So the idea here is that when the image iterator comes across a gif, it immediately starts stepping through its frames at their discovered duration.
        // Then, when incImage/decImage is called, the animated gif timer et al. shut themselves down automatically (and then reinit if the next image is also a gif)
        mAnimatedGifFrameIndex = 0;
        
        
        
        if let data = NSData.init(contentsOfFile: path){
            if let rep = NSBitmapImageRep.init(data: data){
                mAnimatedGifImageRep = rep;
                
                    
                if let frames:NSNumber = mAnimatedGifImageRep?.valueForProperty("NSImageFrameCount") as? NSNumber{
                    print("number of frames in girly gif animation at \(path) is: \(frames)");
                    
                    if(frames.integerValue > 0){
                        
                        mAnimatedGifFrameCount = frames.integerValue;
                        mAnimatedGifImageRep?.setProperty("NSImageCurrentFrame", withValue: 0);
                        if let frameDuration = mAnimatedGifImageRep?.valueForProperty("NSImageCurrentFrameDuration") as? Float{
                            print("frame 0 duration is \(frameDuration)");
                            
                            mIsAnimating = true;//commence the jiggling
                            //TODO: ideally you'd have a timer for each frame (or use a dispatch_after block) such that you could honor the duration of each frame... but they're often uniform, so I declare this close enough
                            mAnimatedGifTimer = NSTimer.scheduledTimerWithTimeInterval(Double(frameDuration), target: self, selector: "incAnimationFrame", userInfo: nil, repeats: true)
                            
                        }
                    }

                }
                
            }
            
        }
        
        
    }
    
    func incAnimationFrame(){
        if(mAnimatedGifFrameIndex == mAnimatedGifFrameCount){
            mAnimatedGifFrameIndex = 0;
        }
        
        var imageRep = mAnimatedGifImageRep!;
        imageRep.setProperty("NSImageCurrentFrame", withValue: mAnimatedGifFrameIndex);
        var frameImage = NSImage.init();
        frameImage.addRepresentation(imageRep);
        
        //respect zoom
        if(ZoomViewController.getCoefficientArray().count == 4){
            frameImage = resize(frameImage, w: frameImage.size.width, h: frameImage.size.height, srcRectArgs: calculateZoomedRectArgs(ZoomViewController.getCoefficientArray()));
        }
        
        //TODO: this is probably a good part of why this app icon gif impl has such a horrific CPU usage -- might be better to add all the imagereps to the applicationiconimage NSImage  and then cycle through them; at least that way you'd be re-using the same NSImage object so there'd be less memory op overhead
        app.applicationIconImage = frameImage;
        mAnimatedGifFrameIndex++;
        
    }

    
    /**
     Turn the app icon into a slideshow of images from the selected folder.  
    */
    func doIterate(){
        
        
        //TODO: at a time delay, cycle automatically through the set of image files found in the image set dir
        if(!mIterating){
            NSLog("begin again with the iteration!");
            mImageIterationTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "incImage", userInfo: nil, repeats: true)
            mIterating = true;
        }else{
            NSLog("enough iteration, already!");
            mImageIterationTimer.invalidate();
            mIterating = false;
        }
        
        
    }
    func doBundledIterate(){
        //TODO: at a time delay, cycle automatically through the set of images bundled with the app (if any)
    }
    
    /**
     Increments the image pointer to load the next image in image set
    */
    func incImage(){
        
        //if animating, stop it
        if(mIsAnimating){
            mAnimatedGifTimer.invalidate();
        }
        
        if(mImagePointer < mImageList.count-1){
            mImagePointer++;
        }else{
            mImagePointer = 0;
        }
        print("about to display image with path \(mImageSetDir+mImageList[mImagePointer]) which comes from the image setdir \(mImageSetDir) followed by the Image filename \(mImageList[mImagePointer]) at Imagepointer \(mImagePointer)");
        var image:String = mImageList[mImagePointer].lowercaseString;
        
        //todo: replace with a substring comparator that specifically looks at the file extension to be sure it matchs ".gif" or ".GIF".  This is oddly hard in Swift
        //todo: detect gifs by looking for a gif format header in the image's hex rep -- the first three bytes should be ascii G, I, and F
        if(image.containsString(".gif")){
            doAnimation(mImageSetDir+image);
        }
        let newIcon:NSImage = NSImage.init(byReferencingFile: mImageSetDir+mImageList[mImagePointer])!;
        app.applicationIconImage = newIcon;
    }
    /**
     Decrements the image pointer to load the previous image in image set
     */
    func decImage(){
        
        //if animating, stop it
        if(mIsAnimating){
            mAnimatedGifTimer.invalidate();
        }

        
        if(mImagePointer > 0){
            mImagePointer--;
        }else{
            mImagePointer = mImageList.count-1;
        }
        
        print("about to display image with path \(mImageSetDir+mImageList[mImagePointer]) which comes from the image setdir \(mImageSetDir) followed by the Image filename \(mImageList[mImagePointer]) at Imagepointer \(mImagePointer)");
        var Image:String = mImageList[mImagePointer].lowercaseString;
        if(Image.containsString(".gif")){
            doAnimation(mImageSetDir+Image);
        }
        let newIcon:NSImage = NSImage.init(byReferencingFile: mImageSetDir+mImageList[mImagePointer])!;
        app.applicationIconImage = newIcon;

    }
    




}

