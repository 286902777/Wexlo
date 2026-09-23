# Wexlo 项目长期记忆

## 项目结构
- Xcode 工程在 `Wexlo/Wexlo.xcodeproj`,源码在 `Wexlo/Wexlo/`(App / Application / Screens / DesignSystem / Navigation / TabBar / Dialogs / Authentication)。
- 主题与配色统一走 `WexloTheme`(background / surface / primaryText / secondaryText / hairline / coral / pink)。

## 关键架构约定
- 导航:`WexloNavigationController` 隐藏系统导航栏,页面自己画返回按钮(如 `backButton.topAnchor = safeArea.top + 18`,35×35);标题若放在 scrollView 内要注意滚动时不要压住返回按钮。
- 可滚动页面:要么 header 固定在 view 上、scrollView 约束到 header 下方(参考 `SettingsViewController`),要么 scrollView 顶部约束到返回按钮下方。
- 帖子媒体封面加载统一模式(参考 `HomeFeedCell.configure`):bundled image → `UIImage(named: mediaAssetName)`;local image → `UIImage(contentsOfFile: WexloLocalContentStore.mediaURL(for:).path)`;video → 先占位再 `WexloVideoMedia.loadFirstFrame(for:storage:)` 异步取首帧;异步场景要用 `representedMediaKey` 防 cell 复用串图。
- 点赞状态:`WexloLikeStore.state(for:userID:)` / `toggleLike`;收藏:`WexloSavedOutfitStore.isSaved` / `setSaved`(按 userID 分桶存 UserDefaults,并 post `.wexloSavedPostDidChange`,ProfileViewController 监听刷新)。用户 ID 约定:authenticated → userID,guest → "guest",absent → "anonymous"。
- `HomeFeedItem` 带 `isLiked` / `isSaved` 两个状态位(默认 false),由 `WexloLocalContentStore.homeFeedItem(for:)` 单点从两个 store 读出;任何展示点赞/收藏 UI 的 cell 都按这两个字段上色(红 = 已点赞/已收藏)。
- 首页数据在 `WexloLocalContentStore.homeFeedItem(for:)` 单点构造 `HomeFeedItem`,`HomeViewController.refreshFeedItems()`(在 `viewWillAppear` 与收藏后调用)会重建 feed 并 reload,所以其他页面改状态后返回首页会自动刷新。

## 踩坑
- `UIButton.Configuration`(如 `.plain()`)存在时 `setTitleColor` 会被忽略,文字颜色必须用 `configuration?.baseForegroundColor`;图片颜色用 `withTintColor` 烘焙。详情页底部操作栏(点赞/Save/Comment)已改回传统 UIButton 属性(setImage/setTitle/setTitleColor/tintColor/titleLabel.font + insets),图标 24pt、字号 14pt,配 `configureActionButton(:systemName:title:tintColor:)`。
- 系统图标定尺寸用 `UIImage(systemName:withConfiguration: UIImage.SymbolConfiguration(pointSize:))`,配合 `button.tintColor` 上色即可(模板图自动着色,不需要 `withTintColor` 烘焙)。
- 首页卡片(HomeFeedCell)与帖子详情页底部操作栏共用同一种 `configureActionButton(_:systemName:title:tintColor:)` 写法:左图右文(heart / bookmark)、默认灰 / 选中红。**当前取值:详情页图标 24pt + 字号 14pt;首页卡片 12pt + 12pt(用户下调过)**,两处不要求一致,以用户确认的视觉为准。
- **xcodebuild 可以在本环境跑通**:`cd Wexlo/Wexlo && xcodebuild -project Wexlo.xcodeproj -scheme Wexlo -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath DerivedData build CODE_SIGNING_ALLOWED=NO`(DerivedData 指到工程内目录,绕过沙箱对默认路径的限制),约 20s 出结果。改完 Swift 优先用它做真编译验证,`xcrun swiftc -parse` 只作快速兜底。
- UIButton 的 `imageEdgeInsets` / `titleEdgeInsets` **不计入 intrinsicContentSize**:用它们做图文间距会让标题溢出按钮宽度、尾部被裁。必须把等量的 4pt 用 `contentEdgeInsets.right` 补回去(contentEdgeInsets 才参与固有尺寸计算),并加 `setContentCompressionResistancePriority(.required, for: .horizontal)` + `titleLabel?.lineBreakMode = .byClipping` 保证永不省略号。
- 用户会在 Xcode 里自行微调视觉参数(如把按钮图标/字号从 24/14 改成 12/12);遇到这类手工改动以用户的实测值为准,不要擅自改回,改代码前先重读文件确认当前值。
