# Acheron

Acheron is a collection of utilties for developing iOS apps.

* Total Lines: 2858


## Loom ORM

A lightweight threadsafe no SQL ORM.

* Dependencies: Odds and Ends
* Classes: Anchor, Basket, Domain, Persist, Loom, SQLitePersist
* Lines: 1233


## AepLayout

A collection of lightweight extensions and convenience methods for laying out iOS screens programatically.  It is particularly useful in making multiple screen sizes look the same.

* Classes: AEViewController, Screen
* Extensions: CALayer, UIView, UIViewController
* Lines: 319


## Pen

* Classes: Pen
* Extensions: NSMutableAttributedString, NSString, UIButton, UILabel
* Lines: 66

Pen is a set of tools that eases working with fonts within UIKit.  Mainly, it is an immutable object, 'Pen' that encaspulates all of the font "attributes"; making them easy to define and access.  Slightly adjusted new Pens can be created via the clone() method.  It also includes a number of extensions to Apple classes the allows Pens to be used directly with them.

Usage:
```
let greenPen: Pen = Pen(font: UIFont(name: "ChicagoFLF", size: 19)!, color: UIColor.green.tint(0.7), alignment: .right)
let whitePen: Pen = greenPen.clone(color: .white)

let attString = NSMutableAttributedString()
attString.append("This is GREEN", pen: greenPen)
attString.append("This is WHITE", pen: whitePen)

let label = UILabel()
label.pen = greenPen

NSString("Hello, White Pen").draw(at: .zero, pen: whitePen)
NSString("Hello, Green Pen").draw(at: .zero, withAttributes: greenPen.attributes)
```

## RGB

* Classes: RGB
* Extensions: UIColor
* Lines: 91

RGB is a set of tools that make it easy to get tints, shades and tones of a color or blend two entirely different colors.  It includes the RGB class which converts color into a vector that can then be manipulated mathematically.  It also includes an extension of UIColor that enables these manipulations to be made directly to UIColor itself.

Usage:
```
let lightBlue = UIColor.blue.tint(0.5)
let greyGreen = UIColor.green.tone(0.5)
let transparentPink = UIColor.red.tint(0.5).alpha(0.5)

let blueRGB = RGB(uiColor: .blue)
let redRGB = RGB(uiColor: .red)
let purpleRGB = (blueRGB + redRGB) * 0.5
let purpleRGB2 = blueRGB.blend(rgb: redRGB, percent: 0.5)
```


## Expandable Table View

Classes and delegates for creating expandable table views.

* Dependencies: AepLayout
* Classes: ExpandableCell, ExpandableTableView
* Lines: 192

## Node View

A view making the display of tabular data easy.

* Dependencies: AepLayout
* Classes: AETableView, Node, NodeCell, NodeColumn, NodeData, NodeHeader, NodeView
* Lines: 316

## AepImage

* Extensions: UIImage, UIImageView
* Lines: 48

AepImage is an extremely light weight asynchoronous image loading and caching tool that stitches into UIImageView, but can also be used from static methods on UIImage directly.  The tool ensures UIImageViews located on UITableViews are handled correctly.  It does not, however, include a disk cache.

Usage:
```
imageView.loadImage(url: "https://aepryus.com/resources/aexels01s.png")
imageView.loadImage(url: "https://aepryus.com/resources/Force3.jpg", placeholder: tempImage) {
    print("Image Loaded")
}
    
UIImage.loadImage(url: "https://aepryus.com/resources/tnEvolizer1.jpg") { (image: UIImage) in
    print("already loaded")
} willLoad: {
    print("will load")
} finishedLoading: { (image: UIImage) in
    print("finished loading")
}
```

## Pond and Pebbles

Asynchronous control flow.

* Classes: Pebble, Pond
* Lines: 156

## Odds and Ends

* Classes: AESync, AETimer, SafeMap, SafeSet, WeakSet, XMLtoAttributes, TripWire
* Extensions: Array, CaseIterable, CGPoint, Comparable, Date, Dictionary, String, UIControl
* Lines: 437

Usage:
```
let button: UIButton = UIButton()
button.addAction {
    print("Hello, Acheron")
}
```
