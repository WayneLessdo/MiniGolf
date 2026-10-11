import UIKit

@main final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "FoldPutt", sessionRole: session.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
    func application(_ application:UIApplication,didDiscardSceneSessions sessions:Set<UISceneSession>) {
        sessions.forEach { FPSceneCheckpoint.discard($0.persistentIdentifier) }
    }

}
