import SwiftUI

extension Keybind {
    func toggleSidebar(fix: Bool = false, _ appViewModel: AppViewModel) {
        guard let contentViewModel = contentViewModelForActiveWindow(appViewModel: appViewModel) else { return }
        if !fix {
            withAnimation(.linear(duration: 0.1)) {
                if contentViewModel.isSidebarFixed {
                    contentViewModel.isSidebarFixed = false
                    contentViewModel.isSidebarShown = false
                } else {
                    contentViewModel.isSidebarShown.toggle()
                }
            }
            return
        }
        contentViewModel.isSidebarShown = false
        withAnimation(.linear(duration: 0.1)) {
            contentViewModel.isSidebarFixed.toggle()
        }
    }
    
    func search(_ appViewModel: AppViewModel) {
        guard let contentViewModel = contentViewModelForActiveWindow(appViewModel: appViewModel) else { return }
        contentViewModel.showInlineSearch.toggle()
    }
    
    func showHistory(_ appViewModel: AppViewModel) {
        guard let contentViewModel = contentViewModelForActiveWindow(appViewModel: appViewModel) else { return }
        contentViewModel.showHistory.toggle()
    }
    
    func zoom(enlarge: Bool = true, _ appViewModel: AppViewModel) {
        guard let contentViewModel = contentViewModelForActiveWindow(appViewModel: appViewModel), let webViewModel = contentViewModel.tabs.first(where: {$0.id == contentViewModel.currentTab})?.webViewModel else { return }
        webViewModel.webView?.evaluateJavaScript("document.body.style.zoom = (parseFloat(document.body.style.zoom || 1.0) \(enlarge ? "+": "-") 0.1)") { (result, error) in
            if let error = error {
                print("Zoom \(enlarge ? "in": "out") error: \(error)")
            }
        }
    }
    
    func resetZoom(_ appViewModel: AppViewModel) {
        guard let contentViewModel = contentViewModelForActiveWindow(appViewModel: appViewModel), let webViewModel = contentViewModel.tabs.first(where: {$0.id == contentViewModel.currentTab})?.webViewModel else { return }
        webViewModel.webView?.evaluateJavaScript("document.body.style.zoom = 1.0") { (result, error) in
            if let error = error {
                print("Zoom reset error: \(error)")
            }
        }
    }
    
    func toggleSidebarOrientation(_ appViewModel: AppViewModel) {
        guard let contentViewModel = contentViewModelForActiveWindow(appViewModel: appViewModel) else {
            print("No contentviewmodel")
            return
        }
        contentViewModel.sidebarOrientation = contentViewModel.sidebarOrientation.other
    }
    
    func createNewWindow(_ appViewModel: AppViewModel, _ openWindow: OpenWindowAction) {
        openWindow(id: "mainWindow")
    }
    
    func togglePasswordSidebar(fix: Bool = false, _ appViewModel: AppViewModel) {
        guard let contentViewModel = contentViewModelForActiveWindow(appViewModel: appViewModel) else { return }
        if !fix {
            withAnimation(.linear(duration: 0.1)) {
                if contentViewModel.isPasswordFixed {
                    contentViewModel.isPasswordFixed = false
                    contentViewModel.isPasswordShown = false
                } else {
                    contentViewModel.isPasswordShown.toggle()
                }
            }
            return
        }
        contentViewModel.isPasswordShown = false
        withAnimation(.linear(duration: 0.1)) {
            contentViewModel.isPasswordFixed.toggle()
        }
    }
    
    func newTab(_ appViewModel: AppViewModel) {
        guard let contentViewModel = contentViewModelForActiveWindow(appViewModel: appViewModel) else { return }
        contentViewModel.triggerNewTab.toggle()
    }
    
    func navigate(back: Bool = true, _ appViewModel: AppViewModel) {
        guard let contentViewModel = contentViewModelForActiveWindow(appViewModel: appViewModel) else { return }
        if let model = contentViewModel.tabs.first(where: {$0.id == contentViewModel.currentTab})?.webViewModel {
            if back {
                model.goBack()
            } else {
                model.goForward()
            }
        }
    }
    
    func navigateTabs(back: Bool = true, _ appViewModel: AppViewModel) {
        guard let contentViewModel = contentViewModelForActiveWindow(appViewModel: appViewModel), contentViewModel.tabs.count > 0 else { return }
        if let currentTab = contentViewModel.tabs.first(where: {$0.id == contentViewModel.currentTab}) {
            currentTab.webViewModel.removeHighlights()
        }
        contentViewModel.showInlineSearch = false
        if back {
            guard let _ = contentViewModel.currentTab, let index = contentViewModel.tabs.firstIndex(where: {$0.id == contentViewModel.currentTab}) else {
                contentViewModel.currentTab = contentViewModel.tabs[0].id
                return
            }
            contentViewModel.currentTab = contentViewModel.tabs[max(0, index - 1)].id
            return
        }
        guard let index = contentViewModel.tabs.firstIndex(where: {$0.id == contentViewModel.currentTab}) else {
            contentViewModel.currentTab = contentViewModel.tabs[contentViewModel.tabs.count - 1].id
            return
        }
        contentViewModel.currentTab = contentViewModel.tabs[min(contentViewModel.tabs.count - 1, index + 1)].id
    }
    
    func closeCurrentTab(_ appViewModel: AppViewModel) {
        guard let contentViewModel = contentViewModelForActiveWindow(appViewModel: appViewModel) else { return }
        
        withAnimation(.linear(duration: 0.2)) {
            guard let id = contentViewModel.currentTab else { return }
            contentViewModel.closeTab(id: id)
        }
    }
    
    func reload(fromSource: Bool = false, _ appViewModel: AppViewModel) {
        guard let contentViewModel = contentViewModelForActiveWindow(appViewModel: appViewModel) else { return }
        if let tab = contentViewModel.tabs.first(where: {$0.id == contentViewModel.currentTab}) {
            if !fromSource {
                tab.webViewModel.webView?.reload()
            } else {
                tab.webViewModel.webView?.reloadFromOrigin()
            }
        }
    }
    
    func toggleTranslucentWindow(_ appViewModel: AppViewModel) {
        guard let contentViewModel = contentViewModelForActiveWindow(appViewModel: appViewModel), let window = contentViewModel.window else { return }
        if window.alphaValue == 1 {
            var translucency = UDKey.tranclucency.doubleValue
            if translucency <= 0 { translucency = 0.4 }
            window.alphaValue = translucency
            window.level = .floating
            window.ignoresMouseEvents = true
            window.acceptsMouseMovedEvents = false
        } else {
            window.alphaValue = 1
            window.level = .normal
            window.ignoresMouseEvents = false
            window.acceptsMouseMovedEvents = true
        }
    }
}
