# Acheron

Acheron is a collection of utilties for developing iOS apps.

* Total Lines: 2881


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

An object and set of extensions to ease using text within iOS.

* Classes: Pen
* Extensions: NSMutableAttributedString, NSString, UIButton, UILabel
* Lines: 71


## RGB

* Classes: RGB
* Extensions: UIColor
* Lines: 91

RGB is a set of tools that make it easy to get tints, shades and tones of a color or blend any two colors.  It includes the RGB class which converts color into a vector allowing for mathematical manipulations of color.  It then includes an extension of UIColor that enables these manipulations to be made directly to UIColor itself.

Usage:
```
    let lightBlue: UIColor = UIColor.blue.tint(0.5)
    let greyGreen: UIColor = UIColor.green.tone(0.5)
    let transparentPink: UIColor = UIColor.red.tint(0.5).alpha(0.5)
    
    let blueRGB: RGB = RGB(uiColor: .blue)
    let redRGB: RGB = RGB(uicolor: .red)
    let purpleRGB: RGB = (blueRGB + redRGB)/2
    let purpleRGB: RGB = blueRGB.blend(rgb: redRGB, percent: 0.5)
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

Extensions for handling server image loading.

* Extensions: UIImage, UIImageView
* Lines: 66

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
