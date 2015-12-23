//
//  MainTabController.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import UIKit

class MainTabController : UITabBarController {
    
    var shouldDismissPlayer: Bool = false
    
    var lastSelectedIndex: Int = 0
    
    override var selectedIndex: Int {
//        get {
//            return super.selectedIndex
//        }
        didSet {
            lastSelectedIndex = oldValue
            switch selectedIndex {
            case MainTabController.TabIndex.playerIndex.rawValue:
                self.tabBar.hidden = true
            default:
                self.tabBar.hidden = false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        selectedIndex = TabIndex.podcastIndex.rawValue
    }
    
    enum TabIndex: Int {
        case mapIndex = 2
        case podcastIndex = 1
        case playerIndex = 0
    }
}

extension MainTabController : UITabBarControllerDelegate{
    func tabBarController(tabBarController: UITabBarController, animationControllerForTransitionFromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let destinationVC = toVC as? PlayerViewController {
            shouldDismissPlayer = false
            return self
        } else if let sourceVC = fromVC as? PlayerViewController {
            shouldDismissPlayer = true
            return self
        } else {
            return nil
        }
    }
}

extension MainTabController: UIViewControllerAnimatedTransitioning {
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView()!
        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        let offScreenBottom = CGAffineTransformMakeTranslation(0, container.frame.height)
        let duration = self.transitionDuration(transitionContext)
        if !shouldDismissPlayer {
            toView.transform = offScreenBottom
            fromView.transform = CGAffineTransformIdentity
            container.addSubview(fromView)
            container.addSubview(toView)
            UIView.animateWithDuration(duration, delay: 0.0, options: .CurveEaseOut, animations: {
                toView.transform = CGAffineTransformIdentity
                if let episode = PodcastPlayer.sharedInstance.getCurrentEpisode() {
                    self.tabBar.alpha = 0
                } else {
                    self.tabBar.alpha = 1
                }
                self.navigationController?.navigationBar.alpha = 0.0
                }, completion: { finished in
                    transitionContext.completeTransition(true)
                    self.shouldDismissPlayer = false
            })
        } else {
            toView.transform = CGAffineTransformIdentity
            fromView.transform = CGAffineTransformIdentity
            container.addSubview(toView)
            container.addSubview(fromView)
            navigationController?.navigationBar.alpha = 0.0
            UIView.animateWithDuration(duration, delay: 0.0, options: .CurveEaseOut, animations: {
                fromView.transform = offScreenBottom
                self.tabBar.alpha = 1
                self.navigationController?.navigationBar.alpha = 1.0
                }, completion: { finished in
                    transitionContext.completeTransition(true)
                    self.shouldDismissPlayer = false
                    fromView.transform = CGAffineTransformIdentity
            })
        }
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
}