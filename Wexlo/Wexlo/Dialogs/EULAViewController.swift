import UIKit

final class EULAViewController: WexloDialogViewController {
    var onAgree: (() -> Void)? { didSet { onConfirm = onAgree } }
    
    init() {
        super.init(
            title: "EULA",
            message: """
Welcome to Wexlo! To make a better community, the following content is strictly prohibited in particular:

1. Any content about child harm, pornography, or material detrimental to children.
2. Fake and harmful messages about recent or current events.
3. Any violence, bullying, explicit content, or other inappropriate material.

If we find any content including but not limited to the above violations, your content will be deleted and your account will be banned. By clicking the button below, you agree to the Terms of Use and Privacy Policy.
""",
            confirmTitle: "Agree"
        )
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}
