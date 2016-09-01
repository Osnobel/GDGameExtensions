//
//  GDGameCenter.swift
//  GDGameCenter
//
//  Created by Bell on 16/5/28.
//  Copyright © 2016年 GoshDo <http://goshdo.sinaapp.com>. All rights reserved.
//

import GameKit

public class GDGameCenter: NSObject, GKGameCenterControllerDelegate {
    // Singleton
    public static func sharedGameCenter() -> GDGameCenter {
        return _sharedInstance
    }
    private static let _sharedInstance = GDGameCenter()
    private override init() {
        super.init()
        // local player has been changed
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GDGameCenter.checkAuthentication), name: GKPlayerAuthenticationDidChangeNotificationName, object: nil)
    }
    // Singleton end
    private var _unsentScores:[GKScore] = []
    private var _unsentAchievements:[GKAchievement] = []
    private var _longin: Bool = false
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public func authenticateLocalPlayer() {
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = { (viewController, error) -> Void in
            if viewController != nil && error == nil{
                UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(viewController!, animated: true, completion: { _ in
                    self.checkAuthentication()
                })
            } else {
                if error != nil {
                    print("[GDGameCenter] Authenticated with error:\(error?.localizedDescription).")
                }
                self.checkAuthentication()
            }
        }
    }

    @objc private func checkAuthentication() {
        if GKLocalPlayer.localPlayer().authenticated {
            self._longin = true
            print("[GDGameCenter] Authenticated Success.")
            // Perform additional tasks for the authenticated player.
            // If unsent scores array has length > 0, try to send saved scores
            if self._unsentScores.count > 0 {
                GKScore.reportScores(self._unsentScores, withCompletionHandler: { (error) -> Void in
                    if error != nil {
                        // If there's an error reporting the scores (again!)
                        print("[GDGameCenter] Report UnsentScores Failure: \(error?.localizedDescription).")
                    } else {
                        // If success, remove successfully sent scores from stored array
                        self._unsentScores.removeAll()
                        print("[GDGameCenter] Report UnsentScores Success.")
                    }
                    
                })
            }
            // If unsent achievements array has length > 0, try to send saved achievements
            if self._unsentAchievements.count > 0 {
                GKAchievement.reportAchievements(self._unsentAchievements, withCompletionHandler: { (error) -> Void in
                    if error != nil {
                        // If there's an error reporting the achievements (again!)
                        print("[GDGameCenter] Report UnsentAchievements Failure: \(error?.localizedDescription).")
                    } else {
                        // If success, remove successfully sent achievements from stored array
                        self._unsentAchievements.removeAll()
                        print("[GDGameCenter] Report UnsentAchievements Success.")
                    }
                    
                })
            }
        } else {
            self._longin = false
            print("[GDGameCenter] Authenticated Failure.")
        }
    }
    
    //MARK: Leaderboards
    public func reportScore(score: Int64, forLeaderboardIdentifier leaderboardIdentifier: String) {
        let scoreReporter = GKScore(leaderboardIdentifier: leaderboardIdentifier)
        scoreReporter.value = score
        if self._longin {
            GKScore.reportScores([scoreReporter], withCompletionHandler: { (error) -> Void in
                if error != nil {
                    // Handle reporting error here by adding object to a serializable dictionary, to be sent again later
                    self._unsentScores.append(scoreReporter)
                    print("[GDGameCenter] Report Score \(score) Failure For \(leaderboardIdentifier).")
                } else {
                    print("[GDGameCenter] Report Score \(score) Success For \(leaderboardIdentifier).")
                }
            })
        } else {
            self._unsentScores.append(scoreReporter)
            print("[GDGameCenter] Report Score \(score) Failure For \(leaderboardIdentifier) with no Authenticated.")
        }
    }
    
    public func loadScoreOfLocalPlayer(leaderboardIdentifier: String, withCompletionHandler completionHandler: ((score: Int64?, error: NSError?) -> Void)?) {
        if self._longin {
            let leaderboard = GKLeaderboard(players: [GKLocalPlayer.localPlayer()])
            leaderboard.identifier = leaderboardIdentifier
            leaderboard.range = NSRange(location: 1, length: 1)
            leaderboard.loadScoresWithCompletionHandler({ (scores, error) -> Void in
                if error != nil {
                    print("[GDGameCenter] Load Score Of Local Player Failure For \(leaderboardIdentifier).")
                }
                completionHandler?(score: scores?.first?.value, error: error)
            })
        } else {
            self.authenticateLocalPlayer()
        }
    }
    
    public func showLeaderboard(leaderboardIdentifier: String) {
        let gameCenterViewController = GKGameCenterViewController()
        gameCenterViewController.viewState = .Leaderboards
        gameCenterViewController.leaderboardIdentifier = leaderboardIdentifier
        gameCenterViewController.gameCenterDelegate = self
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(gameCenterViewController, animated: true, completion: nil)
    }
    
    //MARK: Achievement
    public func reportAchievement(percentComplete: Double, forAchievementIdentifier achievementIdentifier: String) {
        let achievement =  GKAchievement(identifier: achievementIdentifier)
        achievement.percentComplete = percentComplete
        if self._longin {
            GKAchievement.reportAchievements([achievement], withCompletionHandler: { (error) -> Void in
                if error != nil {
                    // Handle reporting error here by adding object to a serializable dictionary, to be sent again later
                    self._unsentAchievements.append(achievement)
                    print("[GDGameCenter] Report Percent Complete \(percentComplete) Failure For \(achievementIdentifier).")
                } else {
                    print("[GDGameCenter] Report Percent Complete \(percentComplete) Success For \(achievementIdentifier).")
                }
            })
        } else {
            self._unsentAchievements.append(achievement)
            print("[GDGameCenter] Report Percent Complete \(percentComplete) Failure For \(achievementIdentifier) with no Authenticated.")
        }
    }
    
    public func loadAchievements(withCompletionHandler completionHandler: ((achievements: [GKAchievement]?,
        error: NSError?) -> Void)?) {
        if self._longin {
            GKAchievement.loadAchievementsWithCompletionHandler({ (achievements, error) -> Void in
                completionHandler?(achievements: achievements, error: error)
            })
        } else {
            self.authenticateLocalPlayer()
        }
    }
    
    //MARK: GKGameCenterControllerDelegate methods
    public func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.gameCenterDelegate = nil
        gameCenterViewController.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}