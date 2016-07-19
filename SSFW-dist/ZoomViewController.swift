//
//  ZoomViewController.swift
//  SSFW
//
//  Created by Jeff Creswell on 2016-06-14.
//  Copyright © 2016 Jeff Creswell. All rights reserved.
//

import Cocoa


class ZoomViewController: NSViewController {
    
    let myAppDelegate:AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
    static var mPointsArray = [NSPoint]();
    
    //todo: this has no business being static, but I couldn't figure out how else to communicate a value from one ViewController to another
    static var mCoefficientArray = [CGFloat]();
    
    override func mouseDown(theEvent: NSEvent) {
        print("pressed mouse in zoom window at \(theEvent.locationInWindow.x),\(theEvent.locationInWindow.y)");
        let xPos = theEvent.locationInWindow.x;
        let yPos = theEvent.locationInWindow.y;
        let windowWidth = self.view.frame.width;
        let windowHeight = self.view.frame.height;
        
        //obviously the best thing would be to show the icon image in an editor window and let the user draw a box around
        // the area they want to use as a source rect for 'zooming', but that's beyond my meager Cocoa skills.  An uglier
        // but still functional solution might be to let the user click four times in the tool window and let those points
        // indicate a relative bounding box for the source rect. Ex. tool window is 500x500 pixels. User clicks at
        //[50,100]->(windowX/windowWidth)*iconImageWidth becomes x of NSMakeRect,(windowY/windowHeight)*iconImageHeight becomes the y of NSMakeRect
        //[450,100]->abs delta x is 400, so 400/windowWidth would be the width coefficient.  Width coefficient*iconImageWidth gives width arg of NSMakeRect. Ditto for
        //           height.
        //[50,400]
        //[450,400]
        //The first clicked point could be the x,y args of NSMakeRect(), and the abs delta x and abs delta y could serve for the width,height args.
        //That wouldn't give us the effect of drawing a box around the icon image where we want to zoom in, however, since the window and icon image are almost certainly different sizes. To resolve the size difference, we need to turn the point and deltas from the window into relative terms.  Specifically, we'll consider them to be coefficients to be applied to bounds such that a point clicked at 20% of the window width will resolve to an x value that is 20% of the icon image width. That should yield the effective zoom region definition we want. For simplicity's sake, we'll mandate a rect drawing procedure wherein the user defines the upper left point first and proceeds clockwise around the rectangle.
        
        if(ZoomViewController.getPointsArray().count < 3){
            ZoomViewController.appendToPointsArray(CGPoint.init(x: xPos, y: yPos));
            
        }else{
            //append fourth point
            ZoomViewController.appendToPointsArray(CGPoint.init(x: xPos, y: yPos));
            
            //now a rect has been defined
            //calculate the coefficientarray
            let xCoef = xPos/windowWidth;
            let yCoef = yPos/windowHeight;
            let widthCoef = (ZoomViewController.getPointsArray()[1].x-ZoomViewController.getPointsArray()[0].x)/windowWidth;
            let heightCoef = (ZoomViewController.getPointsArray()[1].y-ZoomViewController.getPointsArray()[3].y)/windowHeight;//Cocoa figues 0,0 is in the bottom left of a view's frame for some screwy reason, so Y will go down as we move from the first two points to the third and fourth
            
            ZoomViewController.populateCoefficientArray(xCoef,y:yCoef,width:widthCoef,height:heightCoef);
            
            print("the coefficients array in zoom window says x:\(ZoomViewController.getCoefficientArray()[0]),y:\(ZoomViewController.getCoefficientArray()[1]),width:\(ZoomViewController.getCoefficientArray()[2]),height:\(ZoomViewController.getCoefficientArray()[3])");
            
            //then clear points array
            ZoomViewController.clearPointsArray();
            
            
        }
    }
    
    //todo: these functions shouldn't need to be static, but I'm new to Cocoa and I couldn't find a good way
    // to establish communication between instances of extant windows.  I guess I'd need to override something higher
    // than AppDelegate and do a bunch of view init stuff manually that Cocoa otherwise handles for you.  Really missing the
    // good old Android Context::findViewById() method.  What I need is for the coefficient data from ZoomViewController to 
    // be available to ViewController when the 'Zoom' button is pressed.  I suppose the correct MVC approach would be to have the 
    // ZoomViewController communicate its data back to the AppDelegate and then have ViewController simply send a dumb 'zoom requested'
    // signal to AppDelegate which will then take the data from ZoomViewController and the request from ViewController and turn it into
    // an actual zoom operation.  Whatever the case, this issue needs architectural attention.
    static func populateCoefficientArray(x:CGFloat,y:CGFloat,width:CGFloat,height:CGFloat){
        mCoefficientArray.removeAll();//clear the old rect
        mCoefficientArray.append(x);
        mCoefficientArray.append(y);
        mCoefficientArray.append(width);
        mCoefficientArray.append(height);
    }
    
    static func getCoefficientArray()->[CGFloat]{
        
        return mCoefficientArray;
    }
    static func getPointsArray()->[NSPoint]{
        
        return mPointsArray;
    }
    static func appendToPointsArray(point:NSPoint){
        mPointsArray.append(point);
    }
    static func clearPointsArray(){
       
        mPointsArray.removeAll();
        
    }
    static func clearCoefficientArray(){
        mCoefficientArray.removeAll();
        
    }

}
