import UIKit

final class WexloNavigationController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBarHidden(true, animated: false)
        delegate = self
        interactivePopGestureRecognizer?.delegate = self
    }

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        let shouldHideTabBar = viewController !== viewControllers.first
        (tabBarController as? WexloTabBarController)?.setFloatingTabBarHidden(
            shouldHideTabBar,
            animated: animated
        )
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
