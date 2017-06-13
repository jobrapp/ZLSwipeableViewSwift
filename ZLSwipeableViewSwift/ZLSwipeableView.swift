//
//  ZLSwipeableView.swift
//  ZLSwipeableViewSwiftDemo
//
//  Created by Zhixuan Lai on 4/27/15.
//  Copyright (c) 2015 Zhixuan Lai. All rights reserved.
//

import UIKit

class ZLPanGestureRecognizer: UIPanGestureRecognizer {
    
}

public func ==(lhs: ZLSwipeableViewDirection, rhs: ZLSwipeableViewDirection) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public struct ZLSwipeableViewDirection : OptionSet, CustomStringConvertible {
    public var rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    // MARK: NilLiteralConvertible
    public init(nilLiteral: ()) {
        self.rawValue = 0
    }
    
    // MARK: BitwiseOperationsType
    public static var allZeros: ZLSwipeableViewDirection {
        return self.init(rawValue: 0)
    }
    
    public static var None: ZLSwipeableViewDirection       { return self.init(rawValue: 0b0000) }
    public static var Left: ZLSwipeableViewDirection       { return self.init(rawValue: 0b0001) }
    public static var Right: ZLSwipeableViewDirection      { return self.init(rawValue: 0b0010) }
    public static var Up: ZLSwipeableViewDirection         { return self.init(rawValue: 0b0100) }
    public static var Down: ZLSwipeableViewDirection       { return self.init(rawValue: 0b1000) }
    public static var Horizontal: ZLSwipeableViewDirection { return [Left, Right] }
    public static var Vertical: ZLSwipeableViewDirection   { return [Up , Down] }
    public static var All: ZLSwipeableViewDirection        { return [Horizontal , Vertical] }
    
    public static func fromPoint(_ point: CGPoint) -> ZLSwipeableViewDirection {
        switch (point.x, point.y) {
        case let (x, y) where abs(x)>=abs(y) && x>=0:
            return .Right
        case let (x, y) where abs(x)>=abs(y) && x<0:
            return .Left
        case let (x, y) where abs(x)<abs(y) && y<=0:
            return .Up
        case let (x, y) where abs(x)<abs(y) && y>0:
            return .Down
        case (_, _):
            return .None
        }
    }
    
    public var description: String {
        switch self {
        case ZLSwipeableViewDirection.None:
            return "None"
        case ZLSwipeableViewDirection.Left:
            return "Left"
        case ZLSwipeableViewDirection.Right:
            return "Right"
        case ZLSwipeableViewDirection.Up:
            return "Up"
        case ZLSwipeableViewDirection.Down:
            return "Down"
        case ZLSwipeableViewDirection.Horizontal:
            return "Horizontal"
        case ZLSwipeableViewDirection.Vertical:
            return "Vertical"
        case ZLSwipeableViewDirection.All:
            return "All"
        default:
            return "Unknown"
        }
    }
}

open class ZLSwipeableView: UIView {
    // MARK: - Public
    // MARK: Data Source
    open var numPrefetchedViews = 3
    open var nextView: (() -> UIView?)?
    // MARK: Animation
    open var animateView: (_ view: UIView, _ index: Int, _ views: [UIView], _ swipeableView: ZLSwipeableView) -> () = {
        func toRadian(_ degree: CGFloat) -> CGFloat {
            return degree * CGFloat(M_PI/100)
        }
        func rotateView(_ view: UIView, forDegree degree: CGFloat, duration: TimeInterval, offsetFromCenter offset: CGPoint, swipeableView: ZLSwipeableView) {
            UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
                view.center = swipeableView.convert(swipeableView.center, from: swipeableView.superview)
                var transform = CGAffineTransform(translationX: offset.x, y: offset.y)
                transform = transform.rotated(by: toRadian(degree))
                transform = transform.translatedBy(x: -offset.x, y: -offset.y)
                view.transform = transform
            }, completion: nil)
        }
        return {(view: UIView, index: Int, views: [UIView], swipeableView: ZLSwipeableView) in
            let degree = CGFloat(1), offset = CGPoint(x: 0, y: swipeableView.bounds.height*0.3)
            switch index {
            case 0:
                rotateView(view, forDegree: 0, duration: 0.4, offsetFromCenter: offset, swipeableView: swipeableView)
            case 1:
                rotateView(view, forDegree: degree, duration: 0.4, offsetFromCenter: offset, swipeableView: swipeableView)
            case 2:
                rotateView(view, forDegree: -degree, duration: 0.4, offsetFromCenter: offset, swipeableView: swipeableView)
            default:
                rotateView(view, forDegree: 0, duration: 0.4, offsetFromCenter: offset, swipeableView: swipeableView)
            }
        }
    }()
    
    // MARK: Delegate
    open var didStart: ((_ view: UIView, _ atLocation: CGPoint) -> ())?
    open var swiping: ((_ view: UIView, _ atLocation: CGPoint, _ translation: CGPoint) -> ())?
    open var didEnd: ((_ view: UIView, _ atLocation: CGPoint) -> ())?
    open var didSwipe: ((_ view: UIView, _ inDirection: ZLSwipeableViewDirection, _ directionVector: CGVector) -> ())?
    open var didCancel: ((_ view: UIView, _ translation: CGPoint) -> (Bool))?
    open var didTap: ((_ view: UIView) -> ())?
    
    // MARK: Swipe Control
    /// in percent
    open var translationThreshold = CGFloat(0.25)
    open var velocityThreshold = CGFloat(750)
    open var direction = ZLSwipeableViewDirection.Horizontal
    
    open var interpretDirection: (_ topView: UIView, _ direction: ZLSwipeableViewDirection, _ views: [UIView], _ swipeableView: ZLSwipeableView) -> (CGPoint, CGVector) = {(topView: UIView, direction: ZLSwipeableViewDirection, views: [UIView], swipeableView: ZLSwipeableView) in
        let programmaticSwipeVelocity = CGFloat(1500)
        let location = CGPoint(x: topView.center.x, y: topView.center.y*0.7)
        var directionVector: CGVector?
        switch direction {
        case ZLSwipeableViewDirection.Left:
            directionVector = CGVector(dx: -programmaticSwipeVelocity, dy: 0)
        case ZLSwipeableViewDirection.Right:
            directionVector = CGVector(dx: programmaticSwipeVelocity, dy: 0)
        case ZLSwipeableViewDirection.Up:
            directionVector = CGVector(dx: 0, dy: -programmaticSwipeVelocity)
        case ZLSwipeableViewDirection.Down:
            directionVector = CGVector(dx: 0, dy: programmaticSwipeVelocity)
        default:
            directionVector = CGVector(dx: 0, dy: 0)
        }
        return (location, directionVector!)
    }
    open func swipeTopView(inDirection direction: ZLSwipeableViewDirection) {
        if let topView = topView() {
            let (location, directionVector) = interpretDirection(topView, direction, views, self)
            swipeTopView(topView, direction: direction, location: location, directionVector: directionVector)
        }
    }
    open func swipeTopView(fromPoint location: CGPoint, inDirection directionVector: CGVector) {
        if let topView = topView() {
            let direction = ZLSwipeableViewDirection.fromPoint(CGPoint(x: directionVector.dx, y: directionVector.dy))
            swipeTopView(topView, direction: direction, location: location, directionVector: directionVector)
        }
    }
    fileprivate func swipeTopView(_ topView: UIView, direction: ZLSwipeableViewDirection, location: CGPoint, directionVector: CGVector) {
        unsnapView()
        pushView(topView, fromPoint: location, inDirection: directionVector)
        removeFromViews(topView)
        loadViews()
        didSwipe?(topView, direction, directionVector)
    }
    
    // MARK: View Management
    fileprivate var views = [UIView]()
    
    open func topView() -> UIView? {
        return views.first
    }
    
    open func loadViews() {
        if views.count<numPrefetchedViews {
            for _ in (views.count..<numPrefetchedViews) {
                if let nextView = nextView?() {
                    nextView.addGestureRecognizer(ZLPanGestureRecognizer(target: self, action: #selector(ZLSwipeableView.handlePan(_:))))
                    nextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ZLSwipeableView.handleTap(_:))))
                    views.append(nextView)
                    containerView.addSubview(nextView)
                    containerView.sendSubview(toBack: nextView)
                }
            }
        }
        if let _ = topView() {
            animateViews()
        }
    }
    
    // point: in the swipeableView's coordinate
    open func insertTopView(_ view: UIView, fromPoint point: CGPoint) {
        if views.contains(view) {
            print("Error: trying to insert a view that has been added")
        } else {
            if cleanUpWithPredicate({ aView in aView == view }).count == 0 {
                view.center = point
            }
            view.addGestureRecognizer(ZLPanGestureRecognizer(target: self, action: #selector(ZLSwipeableView.handlePan(_:))))
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ZLSwipeableView.handleTap(_:))))
            views.insert(view, at: 0)
            containerView.addSubview(view)
            snapView(view, toPoint: convert(center, from: superview))
            animateViews()
        }
    }
    
    fileprivate func animateViews() {
        if let topView = topView() {
            for gestureRecognizer in topView.gestureRecognizers! {
                if gestureRecognizer.state != .possible {
                    return
                }
            }
        }
        
        for i in (0..<views.count) {
            let view = views[i]
            view.isUserInteractionEnabled = i == 0
            animateView(view, i, views, self)
        }
    }
    
    open func discardViews() {
        unsnapView()
        detachView()
        animator.removeAllBehaviors()
        for aView in views {
            removeFromContainerView(aView)
        }
        views.removeAll(keepingCapacity: false)
    }
    
    fileprivate func removeFromViews(_ view: UIView) {
        for i in 0..<views.count {
            if views[i] == view {
                view.isUserInteractionEnabled = false
                views.remove(at: i)
                return
            }
        }
    }
    fileprivate func removeFromContainerView(_ aView: UIView) {
        for gestureRecognizer in aView.gestureRecognizers! {
            if gestureRecognizer.isKind(of: ZLPanGestureRecognizer.classForCoder()) {
                aView.removeGestureRecognizer(gestureRecognizer)
            }
        }
        aView.removeFromSuperview()
    }
    
    // MARK: - Private properties
    fileprivate var containerView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate func setup() {
        animator = UIDynamicAnimator(referenceView: self)
        pushAnimator = UIDynamicAnimator(referenceView: self)
        
        addSubview(containerView)
        addSubview(anchorContainerView)
    }
    
    deinit {
        timer?.invalidate()
        animator.removeAllBehaviors()
        pushAnimator.removeAllBehaviors()
        views.removeAll()
        pushBehaviors.removeAll()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = bounds
    }
    
    // MARK: Animator
    fileprivate var animator: UIDynamicAnimator!
    static fileprivate let anchorViewWidth = CGFloat(1000)
    fileprivate var anchorView = UIView(frame: CGRect(x: 0, y: 0, width: anchorViewWidth, height: anchorViewWidth))
    fileprivate var anchorContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    
    func handleTap(_ recognizer: UITapGestureRecognizer) {
        let topView = recognizer.view!
        didTap?(topView)
    }
    
    func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self)
        let location = recognizer.location(in: self)
        let topView = recognizer.view!
        
        switch recognizer.state {
        case .began:
            unsnapView()
            attachView(topView, toPoint: location)
            didStart?(topView, location)
        case .changed:
            unsnapView()
            attachView(topView, toPoint: location)
            swiping?(topView, location, translation)
        case .ended,.cancelled:
            detachView()
            let velocity = recognizer.velocity(in: self)
            let velocityMag = velocity.magnitude
            
            let directionSwiped = ZLSwipeableViewDirection.fromPoint(translation)
            let directionChecked = directionSwiped.intersection(direction) != .None
            let signChecked = CGPoint.areInSameTheDirection(translation, p2: velocity)
            let translationChecked = abs(translation.x) > translationThreshold * bounds.width ||
                abs(translation.y) > translationThreshold * bounds.height
            let velocityChecked = velocityMag > velocityThreshold
            if directionChecked && signChecked && (translationChecked || velocityChecked){
                let normalizedTrans = translation.normalized
                let throwVelocity = max(velocityMag, velocityThreshold)
                let directionVector = CGVector(dx: normalizedTrans.x*throwVelocity, dy: normalizedTrans.y*throwVelocity)
                
                swipeTopView(topView, direction: directionSwiped, location: location, directionVector: directionVector)
                
                //                pushView(topView, fromPoint: location, inDirection: directionVector)
                //                removeFromViews(topView)
                //                didSwipe?(view: topView, inDirection: ZLSwipeableViewDirection.fromPoint(translation))
                //                loadViews()
            }else {
                let shouldSnapBack = didCancel?(topView, translation)
                if (shouldSnapBack!){
                    snapView(topView, toPoint: convert(center, from: superview))
                }
            }
            didEnd?(topView, location)
        default:
            break
        }
    }
    
    fileprivate var snapBehavior: UISnapBehavior?
    fileprivate func snapView(_ aView: UIView, toPoint point: CGPoint) {
        unsnapView()
        snapBehavior = UISnapBehavior(item: aView, snapTo: point)
        snapBehavior!.damping = 0.75
        animator.addBehavior(snapBehavior!)
    }
    fileprivate func unsnapView() {
        if snapBehavior != nil{
            animator.removeBehavior(snapBehavior!)
            snapBehavior = nil
        }
    }
    
    fileprivate var touchOffset = CGPoint.zero
    
    fileprivate var attachmentViewToAnchorView: UIAttachmentBehavior?
    fileprivate var attachmentAnchorViewToPoint: UIAttachmentBehavior?
    fileprivate func attachView(_ aView: UIView, toPoint point: CGPoint) {
        
        
        if let _ = attachmentViewToAnchorView, let attachmentAnchorViewToPoint = attachmentAnchorViewToPoint {
            var p = point
            p.x = point.x + touchOffset.x
            p.y = point.y + touchOffset.y
            
            attachmentAnchorViewToPoint.anchorPoint = p
        } else {
            
            let center = aView.center
            let offset : CGFloat = 22
            
            touchOffset.x = center.x - point.x
            touchOffset.y = center.y - point.y - offset
            
            var newp = point
            newp.x = point.x + touchOffset.x
            newp.y = point.y + touchOffset.y
            
            anchorView.center = newp
            anchorView.backgroundColor = UIColor.blue
            anchorView.isHidden = true
            anchorContainerView.addSubview(anchorView)
            
            // attach aView to anchorView
            
            attachmentViewToAnchorView = UIAttachmentBehavior(item: aView, offsetFromCenter: UIOffset(horizontal: -(center.x - newp.x), vertical: -(center.y - newp.y + offset)), attachedTo: anchorView, offsetFromCenter: UIOffset.zero)
            attachmentViewToAnchorView!.length = 0
            
            // attach anchorView to point
            attachmentAnchorViewToPoint = UIAttachmentBehavior(item: anchorView, offsetFromCenter: UIOffsetMake(0, offset), attachedToAnchor: newp)
            attachmentAnchorViewToPoint!.damping = 5
            attachmentAnchorViewToPoint!.length = 0
            
            animator.addBehavior(attachmentViewToAnchorView!)
            animator.addBehavior(attachmentAnchorViewToPoint!)
        }
    }
    fileprivate func detachView() {
        if attachmentViewToAnchorView != nil{
            animator.removeBehavior(attachmentViewToAnchorView!)
            animator.removeBehavior(attachmentAnchorViewToPoint!)
        }
        attachmentViewToAnchorView = nil
        attachmentAnchorViewToPoint = nil
    }
    
    // MARK: pushAnimator
    fileprivate var pushAnimator: UIDynamicAnimator!
    fileprivate var timer: Timer?
    fileprivate var pushBehaviors = [(UIView, UIView, UIAttachmentBehavior, UIPushBehavior)]()
    func cleanUp(_ timer: Timer) {
        cleanUpWithPredicate() { aView in
            !self.convert(aView.frame, to: nil).intersects(UIScreen.main.bounds)
        }
        if pushBehaviors.count == 0 {
            timer.invalidate()
            self.timer = nil
        }
    }
    fileprivate func cleanUpWithPredicate(_ predicate: (UIView) -> Bool) -> [Int] {
        var indexes = [Int]()
        for i in 0..<pushBehaviors.count {
            let (anchorView, aView, attachment, push) = pushBehaviors[i]
            if predicate(aView) {
                anchorView.removeFromSuperview()
                removeFromContainerView(aView)
                pushAnimator.removeBehavior(attachment)
                pushAnimator.removeBehavior(push)
                indexes.append(i)
            }
        }
        
        for index in indexes.reversed() {
            pushBehaviors.remove(at: index)
        }
        return indexes
    }
    
    fileprivate func pushView(_ aView: UIView, fromPoint point: CGPoint, inDirection direction: CGVector) {
        let anchorView = UIView(frame: CGRect(x: 0, y: 0, width: ZLSwipeableView.anchorViewWidth, height: ZLSwipeableView.anchorViewWidth))
        anchorView.center = point
        anchorView.backgroundColor = UIColor.green
        anchorView.isHidden = true
        anchorContainerView.addSubview(anchorView)
        
        let p = aView.convert(aView.center, from: aView.superview)
        let point = aView.convert(point, from: aView.superview)
        let attachmentViewToAnchorView = UIAttachmentBehavior(item: aView, offsetFromCenter: UIOffset(horizontal: -(p.x - point.x), vertical: -(p.y - point.y)), attachedTo: anchorView, offsetFromCenter: UIOffset.zero)
        attachmentViewToAnchorView.length = 0
        
        let pushBehavior = UIPushBehavior(items: [anchorView], mode: .instantaneous)
        pushBehavior.pushDirection = direction
        
        pushAnimator.addBehavior(attachmentViewToAnchorView)
        pushAnimator.addBehavior(pushBehavior)
        
        pushBehaviors.append((anchorView, aView, attachmentViewToAnchorView, pushBehavior))
        
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(ZLSwipeableView.cleanUp(_:)), userInfo: nil, repeats: true)
        }
    }
    
    // MARK: - ()
}

extension CGPoint {
    var normalized: CGPoint {
        return CGPoint(x: x/magnitude, y: y/magnitude)
    }
    var magnitude: CGFloat {
        return CGFloat(sqrtf(powf(Float(x), 2) + powf(Float(y), 2)))
    }
    static func areInSameTheDirection(_ p1: CGPoint, p2: CGPoint) -> Bool {
        func signNum(_ n: CGFloat) -> Int {
            return (n < 0.0) ? -1 : (n > 0.0) ? +1 : 0
        }
        return signNum(p1.x) == signNum(p2.x) && signNum(p1.y) == signNum(p2.y)
    }
}
