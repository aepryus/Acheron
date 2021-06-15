# Acheron

Acheron is a collection of utilties for developing iOS apps.

* Total Lines: 2882


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
* Lines: 315

## AepImage

* Extensions: UIImage, UIImageView
* Lines: 48

AepImage is an extremely light weight asynchoronous image loading and caching tool that stitches into UIImageView, but can also be used from static methods on UIImage directly.  The tool ensures UIImageViews located on UITableViews are handled correctly.  It does not include a disk cache.

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

* Classes: Pebble, Pond, BackgroundPond
* Lines: 177

Pond and Pebbles is an asynchronous control flow system that greatly helps detangle complex asynchronous tasks like app initialization.  Through the BackgroundPond it also makes finishing up asynchronous tasks after your app is closed much easier.

Usage:
```
class BootPond: Pond {
    lazy var needNotMigrate: Pebble = {/*...*/}()
    lazy var migrate: Pebble = {/*...*/}
    lazy var ping: Pebble = {
        pebble(name: "Ping") { (complete: @escaping (Bool) -> ()) in
            Pequod.ping { complete(true) }
                failure: { complete(false) }
        }
    }()

    lazy var loadOTID: Pebble = {
        pebble(name: "Load OTID") { (complete: @escaping (Bool) -> ()) in
            complete(Pequod.loadOTID() && Pequod.loadExpired())
        }
    }()
    lazy var loadUser: Pebble = {
        pebble(name: "Load User") { (complete: (Bool) -> ()) in
            complete(Pequod.loadUser())
        }
    }()
    lazy var loadToken: Pebble = {
        pebble(name: "Load Token") { (complete: (Bool) -> ()) in
            complete(Pequod.loadToken())
        }
    }()

    lazy var isLocallySubscribed: Pebble = {/*...*/}()
    lazy var isRemotelySubscribed: Pebble = {/*...*/}()

    lazy var receiptValidation: Pebble = {/*...*/}()
    lazy var userLogin: Pebble = {/*...*/}()
    lazy var otidLogin: Pebble = {/*...*/}()

    lazy var showOffline: Pebble = {/*...*/}()
    lazy var showSubscribe: Pebble = {/*...*/}()
    lazy var showSignUp: Pebble = {/*...*/}()
    lazy var queryCloud: Pebble = {/*...*/}()
    lazy var startOovium: Pebble = {/*...*/}()

    lazy var invalid: Pebble = {/*...*/}()

// Init ============================================================================================
    override init() {
         super.init()

        loadOTID.ready = { true }
        loadToken.ready = { true }
        loadUser.ready = { true }
        needNotMigrate.ready = { true }
        ping.ready = { true }
        queryCloud.ready = { true }

        migrate.ready = { self.needNotMigrate.failed }

        isLocallySubscribed.ready = { self.loadToken.succeeded }
        isRemotelySubscribed.ready = {
            self.ping.succeeded
            && self.isLocallySubscribed.failed
        }

        userLogin.ready = {
            self.ping.succeeded
            && self.loadToken.failed
            && self.loadUser.succeeded
        }

        receiptValidation.ready = {
            self.ping.succeeded
            && self.loadToken.failed
            && self.loadOTID.failed
            && (self.loadUser.failed || self.userLogin.failed)
        }

        otidLogin.ready = {
            self.ping.succeeded
            && self.loadToken.failed
            && (self.loadOTID.succeeded || self.receiptValidation.succeeded)
            && (self.loadUser.failed || self.userLogin.failed)
        }

        showOffline.ready = {
            self.ping.failed
            && self.loadToken.failed
        }

        showSubscribe.ready = {
            self.ping.succeeded
            && (self.receiptValidation.failed || self.isRemotelySubscribed.failed)
        }

        showSignUp.ready = {
            self.ping.succeeded
            && self.loadToken.succeeded
            && self.loadOTID.succeeded
            && (self.isLocallySubscribed.succeeded || self.isRemotelySubscribed.succeeded)
            && self.loadUser.failed
        }

        startOovium.ready = {
            self.loadToken.succeeded
            && self.loadOTID.succeeded
            && (self.loadUser.succeeded || self.ping.failed)
            && (self.isLocallySubscribed.succeeded || self.isRemotelySubscribed.succeeded)
            && (self.needNotMigrate.succeeded || self.migrate.succeeded)
            && self.queryCloud.succeeded
        }

        invalid.ready = {
            self.loadToken.succeeded
            && self.loadOTID.failed
        }
    }
}

class ExitPond: BackgroundPond {
    lazy var saveAether: Pebble = {
        pebble(name: "Save Aether") { (complete: @escaping (Bool) -> ()) in
            Oovium.aetherView.saveAether { (success: Bool) in
                complete(success)
            }
        }
    }()

    init() {
        super.init { print("ExitPond timed out without completing.") }
        saveAether.ready = { true }
    }
}

class OoviumDelegate: UIResponder, UIApplicationDelegate {
    let bootPond: BootPond = BootPond()
    let exitPond: ExitPond = ExitPond()
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        bootPond.start()
        return true
    }
    func applicationWillResignActive(_ application: UIApplication) {
        exitPond.start()
    }
}
```

It also includes mechanisms for writing tests for various asynchronous pathways:
```
XCTAssert(pond.test(shouldSucceed: [
    pond.needNotMigrate,
    pond.ping,
    pond.queryCloud,
    pond.showSubscribe,
], shouldFail: [
    pond.loadOTID,
    pond.loadUser,
    pond.loadToken,
    pond.receiptValidation,
]))
```

## Odds and Ends

* Classes: AESync, AETimer, SafeMap, SafeSet, WeakSet, XMLtoAttributes, TripWire
* Extensions: Array, CaseIterable, CGPoint, Comparable, Date, Dictionary, String, UIControl
* Lines: 441

Usage:
```
let button: UIButton = UIButton()
button.addAction {
    print("Hello, Acheron")
}
```
