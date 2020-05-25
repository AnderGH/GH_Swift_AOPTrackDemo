
参考文章：[iOS 无痕埋点解决方案—— AOP 篇（1）](https://www.jianshu.com/p/2c68896aeb9b)

### 一、AOP面向切面编程

`AOP`全称叫`Aspect-Oriented Programming`，中文名叫面向切面编程，在`iOS`平台中，`AOP`一般使用`Runtime`实现

### 二、代码实现

本文[`demo`](https://github.com/AnderGH/AOPDemo)

在`UIKit`提供的用户交互接口里，主要可以分为两种：

- `Delegate`类`UITableView、UICollectionView`的点击事件，特点是方法名定死，使用`weak`属性持有响应对象
- `Target-Action`类`UIControl、UIGestureRecognizer`的回调事件，特点是方法名可自定义，方法参数可有可无，使用`weak`属性持有响应对象，支持多个响应者

#### 1、Delegate类的交互

通常会拦截`setDelegate:`的方法，此时拦截到的`delegate`对象即为响应对象，再通过判断该响应对象是否实现了相应的代理方法，构建相同的方法进行交换，网上百度到的大部分都是这种实现的逻辑

但此方案存在如下问题：

- 如果父类实现了`setDelegate:`和相应的代理方法，而具体的业务逻辑是由子类`override`重写的代理方法，那么判断到的埋点数据有可能存在问题
- 如果同一个页面有多个`UITableView`，那么`setDelegate:`方法也会实现多次，此时需要防止出现多重交换的情况

参考文章中给出了其他方案：
1. 拦截`setDelegate:`方法，重新创建一个`proxy`类绑定代理并实现相应的代理方法，并将该`proxy`类的对象交换给系统的`delegate`
2. 使用`Runtime`将自定义的`proxy`类的对象添加到控件中持有
3. 当触发代理方法时，系统实际持有`delegate`属性是`proxy`类的对应，会将触发方法发送到`proxy`类中，此时就可以进一步判断是否需要将代理方法继续转发到业务层

```
import UIKit

/// 使用此类替代系统的delegate
class GHUITableViewDelegateProxy: NSObject, UITableViewDelegate {
    
    weak var delegate: UITableViewDelegate?
    
    override func responds(to aSelector: Selector!) -> Bool {
        var hasSelector: Bool = false
        if self.delegate == nil {
            return hasSelector
        }
        hasSelector = self.delegate?.responds(to: aSelector) ?? true
        return hasSelector
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if self.delegate == nil {
            return super.forwardingTarget(for: aSelector)
        }
        if self.delegate?.responds(to: aSelector) == false {
            return super.forwardingTarget(for: aSelector)
        }
        return self.delegate
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.delegate == nil {
            return
        }
        if (self.delegate?.responds(to: #selector(tableView(_:didSelectRowAt:)))) == false {
            return
        }
        
        UITableViewTrack.shared.trackTableView(tableView, didSelectRowAt: indexPath)
        
        self.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
    }
}

private func swizzle(_ tableView: UITableView.Type) {
    let selectors: Array<Array<Selector>> = [
        [
            #selector(setter: tableView.delegate),
            #selector(tableView.gh_setDelegate(_:))
        ],
    ]
    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]

        let originalMethod: Method? = class_getInstanceMethod(tableView, originalSelector)
        let swizzledMethod: Method? = class_getInstanceMethod(tableView, swizzledSelector)
        
        if originalMethod == nil {
            continue
        }
        
        let didAddMethod: Bool = class_addMethod(tableView, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        if didAddMethod {
            class_replaceMethod(tableView, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
}

var ghUITableViewDelegateProxyKey = "GHUITableViewDelegateProxyKey"

extension UITableView {
    
    var ghUITableViewDelegateProxy: GHUITableViewDelegateProxy? {
        set {
            objc_setAssociatedObject(self, &ghUITableViewDelegateProxyKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return objc_getAssociatedObject(self, &ghUITableViewDelegateProxyKey) as? GHUITableViewDelegateProxy
        }
    }
        
    private static let dispatchOnceTime: Void = {
        swizzle(UITableView.self)
    }()
    
    @objc open class func startAOP() {
        guard self === UITableView.self else { return }
        UITableView.dispatchOnceTime
    }
    
    // MARK: 交换的方法
    
    // 交换setdelegate的方法
    @objc func gh_setDelegate(_ delegate: UITableViewDelegate?) {
        
        // 使用GHUITableViewDelegateProxy替代原来系统的UITableViewDelegate
        self.ghUITableViewDelegateProxy = GHUITableViewDelegateProxy()
        self.ghUITableViewDelegateProxy?.delegate = delegate
        
        self.gh_setDelegate(self.ghUITableViewDelegateProxy)
    }
}

```

#### 2、Target-Action类的交互

![image_1.png](image_1.png)

按照参考文章中上图的逻辑设计代码如下：

```
import UIKit

/// 自定义一个action类，由此类的实例对象替代外部传入的action
class GHUITapGestureRecognizerAction: NSObject {
    
    // 弱应用，防止循环应用
    weak var target: UIResponder?
    var action: Selector?
    
    @objc func ghGestureRecognizerAction(sender: UIGestureRecognizer?) -> Void {
        if self.target == nil {
            return
        }
        if self.action == nil {
            return
        }
        
        UITapGestureRecognizerTrack.shared.trackGRAction(sender as? UITapGestureRecognizer, action: self.action!, target: self.target)
        
        if ((target?.responds(to: action)) == true) {
            target?.perform(action, with: sender)
        }
    }
}

var ghGestureActionsKey: String = "GHGestureActionsKey"

extension UIResponder {
    /// 使用runtime给UIResponder扩展一个属性
    var ghGestureActions: Array<GHUITapGestureRecognizerAction>? {
        set {
            objc_setAssociatedObject(self, &ghGestureActionsKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return objc_getAssociatedObject(self, &ghGestureActionsKey) as? Array<GHUITapGestureRecognizerAction>
        }
    }
}

private func swizzle(_ gesture: UITapGestureRecognizer.Type) {
    let selectors: Array<Array<Selector>> = [
        [
            #selector(UITapGestureRecognizer.init(target:action:)),
            #selector(gesture.gh_init(target:action:))
        ],
        [
            #selector(gesture.addTarget(_:action:)),
            #selector(gesture.gh_addTarget(_:action:))
        ],
    ]
    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]
        
        let originalMethod: Method? = class_getInstanceMethod(gesture, originalSelector)
        let swizzledMethod: Method? = class_getInstanceMethod(gesture, swizzledSelector)
        
        if originalMethod == nil {
            continue
        }
        
        let didAddMethod: Bool = class_addMethod(gesture, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        if didAddMethod {
            class_replaceMethod(gesture, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
}

extension UITapGestureRecognizer {
    private static let dispatchOnceTime: Void = {
        swizzle(UITapGestureRecognizer.self)
    }()
    
    @objc open class func startAOP() {
        guard self === UITapGestureRecognizer.self else { return }
        UITapGestureRecognizer.dispatchOnceTime
    }
    
    // MARK: 交换的方法
    
    @objc func gh_init(target: Any?, action: Selector?) -> UIGestureRecognizer {
        if target == nil {
            return self.gh_init(target: target, action: action);
        }
        if (target as? UIResponder) == nil {
            return self.gh_init(target: target, action: action);
        }
        
        // 初始化判断
        if (target as? UIResponder)?.ghGestureActions == nil {
            (target as? UIResponder)?.ghGestureActions = []
        }
        
        // 一个手势对应一个GHUITapGestureRecognizerAction属性，再由target去强制有所有的GHUITapGestureRecognizerAction
        let ghAction = GHUITapGestureRecognizerAction()
        ghAction.target = (target as? UIResponder)
        ghAction.action = action
        
        (target as? UIResponder)?.ghGestureActions?.append(ghAction)
        
        return self.gh_init(target: ghAction, action: #selector(ghAction.ghGestureRecognizerAction(sender:)))
    }
    
    @objc func gh_addTarget(_ target: Any, action: Selector) {
        if (target as? UIResponder) == nil {
            return self.gh_addTarget(target, action: action);
        }
        
        if (target as? UIResponder)?.ghGestureActions == nil {
            (target as? UIResponder)?.ghGestureActions = []
        }
        
        let ghAction = GHUITapGestureRecognizerAction()
        ghAction.target = (target as? UIResponder)
        ghAction.action = action
        
        (target as? UIResponder)?.ghGestureActions?.append(ghAction)
        
        return self.gh_addTarget(ghAction, action: #selector(ghAction.ghGestureRecognizerAction(sender:)))
    }
}

```

### 三、第三方库

很多第三方库也有功能强大的`AOP`逻辑，本文主要是轻量级的代码实现，其他第三方库暂不做介绍






