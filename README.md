# Acheron

Acheron is a collection of utilties for developing iOS apps.

* Total Lines: 2565


## Loom ORM

A lightweight threadsafe no SQL ORM.

* Dependencies: Odds and Ends
* Classes: Anchor, Basket, Domain, Persist, Loom, SQLitePersist
* Lines: 1254


## AepLayout

A collection of lightweight extensions and convenience methods for laying out iOS screens programatically.  It is particularly useful in making multiple screen sizes look the same.

* Classes: AEViewController
* Extensions: CALayer, UIView, UIViewController
* Lines: 247


## Pen

An object and set of extensions to ease using text within iOS.

* Classes: Pen
* Extensions: NSMutableAttributedString, NSString, UILabel
* Lines: 60


## RGB

A set of tools for working with color.

* Classes: RGB
* Extensions: UIColor
* Lines: 92


## Expandable Table View

An object and set delegate protocol for creating expandable tables.

* Dependencies: AepLayout
* Classes: ExpandableCell, ExpandableTableView
* Lines: 191

## Node View

A view making the display of tabular data easy.

* Dependencies: AepLayout
* Classes: AETableView, Node, NodeCell, NodeColumn, NodeData, NodeHeader, NodeView
* Lines: 281

## AepImage

Extensions for handling server image loading.

* Extensions: UIImage, UIImageView
* Lines: 66

## Pebbles

Asynchronous control flow.

* Classes: Pebble, Gizzard
* Lines: 70

## Odds and Ends

* Classes: AETimer, SafeMap, WeakSet, TripWire
* Extensions: Array, CGPoint, Collection, Date, Dictionary, String, UIControl
* Lines: 299

Usage:
```
    let button: UIButton = UIButton()
    button.addAction {
        print("Hello, Acheron")
    }
```
