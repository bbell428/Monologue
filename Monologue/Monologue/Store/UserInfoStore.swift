//
//  UserInfoStore.swift
//  Monologue
//
//  Created by 김종혁 on 10/15/24.
//

import Foundation
import Observation
import FirebaseCore
import FirebaseFirestore
import SwiftUICore

@MainActor
class UserInfoStore: ObservableObject {
    private var authManager: AuthManager = .init()
    private var memoStore: MemoStore = .init()
    private var columnStore: ColumnStore = .init()
    @Published var userInfo: UserInfo? = nil
    @Published var elseUserInfo: UserInfo? = nil
    
    @Published var followers: [UserInfo] = []
    @Published var followings: [UserInfo] = []
    
    @Published var isFollowingStatus: [String: Bool] = [:] // 각 유저에 대한 팔로우 상태 추적
    @Published var isFollowingMe: [String: Bool] = [:] // 각 유저가 나를 팔로우하는지 여부

    @Published var followersCount: Int = 0
    @Published var followingsCount: Int = 0
    
    @Published var memoCount: [String: Int] = [:] // 닉네임별 메모 개수 저장
    @Published var columnCount: [String: Int] = [:] // 닉네임별 칼럼 개수 저장
    
    @Published var blockedUsers: [UserInfo] = []
    
    private var listener: ListenerRegistration?
    
    // 로그인 시 사용자(닉네임, 가입날짜) 파베에 추가
    func addUserInfo(_ user: UserInfo) async {
        do {
            let db = Firestore.firestore()
            
            try await db.collection("User").document(user.email).setData([
                "uid": user.uid,
                "nickname": user.nickname,
                "registrationDate": Timestamp(date: user.registrationDate),
                "preferredCategories": user.preferredCategories,
                "profileImageName": user.profileImageName,
                "introduction": user.introduction,
                "followings": user.followings,
                "followers": user.followers,
                "blocked": user.blocked,
                "likesMemos": user.likesMemos,
                "likesColumns": user.likesColumns
            ])
            
            print("Document successfully written!")
        } catch {
            print("Error writing document: \(error)")
        }
    }
    
    // 사용자 정보 업데이트 (registrationDate는 업데이트되지 않음)
    func updateUserInfo(_ user: UserInfo) async {
        do {
            let db = Firestore.firestore()
            
            try await db.collection("User").document(user.email).setData([
                "uid": user.uid,
                "nickname": user.nickname,
                "preferredCategories": user.preferredCategories,
                "profileImageName": user.profileImageName,
                "introduction": user.introduction,
                "followings": user.followings,
                "followers": user.followers,
                "blocked": user.blocked,
                "likesMemos": user.likesMemos,
                "likesColumns": user.likesColumns
            ])
            
            print("Document successfully updated!")
        } catch {
            print("Error updating document: \(error)")
        }
    }
    
    // 로드하는 부분
    func loadUserInfo(email: String) async {
        do {
            let db = Firestore.firestore()
            let document = try await db.collection("User").document(email).getDocument()
            
            guard let docData = document.data() else {
                print("No user data found for email: \(email)")
                return
            }
            
            let uid: String = docData["uid"] as? String ?? ""
            let nickname: String = docData["nickname"] as? String ?? ""
            let registrationDate: Date = (docData["registrationDate"] as? Timestamp)?.dateValue() ?? Date()
            let preferredCategories: [String] = docData["preferredCategories"] as? [String] ?? []
            let profileImageName: String = docData["profileImageName"] as? String ?? ""
            let introduction: String = docData["introduction"] as? String ?? ""
            let followings: [String] = docData["followings"] as? [String] ?? []
            let followers: [String] = docData["followers"] as? [String] ?? []
            let blocked: [String] = docData["blocked"] as? [String] ?? []
            let likesMemos: [String] = docData["likesMemos"] as? [String] ?? []
            let likesColumns: [String] = docData["likesColumns"] as? [String] ?? []
            
            // `userInfoStore` 업데이트
            self.userInfo = UserInfo(
                uid: uid,
                email: email,
                nickname: nickname,
                registrationDate: registrationDate,
                preferredCategories: preferredCategories,
                profileImageName: profileImageName,
                introduction: introduction,
                followers: followers,
                followings: followings,
                blocked: blocked,
                likesMemos: likesMemos,
                likesColumns: likesColumns
            )
            //            print("User info loaded successfully: \(String(describing: userInfo))")
            
        } catch {
            print("Error loading user info: \(error)")
        }
    }
    
    // 이메일에 따른 유저들의 정보를 배열로 불러오는 함수(유저 목록에 사용)
    func loadUsersInfoByEmail(emails: [String]) async throws -> [UserInfo] {
        guard !emails.isEmpty else {
            return []
        }
        
        let db = Firestore.firestore()
        
        let querySnapshot = try await db.collection("User")
            .whereField(FieldPath.documentID(), in: emails) // 배열로 변경
            .getDocuments()
        
        var usersInfo: [UserInfo] = []
        
        for document in querySnapshot.documents {
            let userInfo = UserInfo(document: document)
            usersInfo.append(userInfo)
        }
        
        return usersInfo
    }
    
    // 메모 개수
    func getMemoCount(email: String) async throws -> Int {
        let memos = try await memoStore.loadMemosByUserEmail(email: email)
        return memos.count
    }
    
    // 칼럼 개수
    func getColumnCount(email: String) async throws -> Int {
        let columns = try await columnStore.loadColumnsByUserEmail(email: email)
        return columns.count
    }
    
    // MARK: - UserInfo 제거
    func deleteUserInfo(email: String) async throws {
        let db = Firestore.firestore()
        
        do {
            try await db.collection("User").document(email).delete()
        } catch {
            throw error
        }
    }
    
    // MARK: - Follow 관련 로직
    // 팔로우 로직
    func followUser(targetUserEmail: String) async {
        let db = Firestore.firestore()
        let currentUserEmail = authManager.email
        
        guard !targetUserEmail.isEmpty else {
            print("Target user email is empty.")
            return
        }
        
        guard currentUserEmail != targetUserEmail else {
            print("You cannot follow yourself.")
            return
        }
        
        let currentUserRef = db.collection("User").document(currentUserEmail)
        let targetUserRef = db.collection("User").document(targetUserEmail)
        
        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                // 현재 유저의 followings에 타겟 유저 추가
                transaction.updateData([
                    "followings": FieldValue.arrayUnion([targetUserEmail])
                ], forDocument: currentUserRef)
                
                // 타겟 유저의 followers에 현재 유저 추가
                transaction.updateData([
                    "followers": FieldValue.arrayUnion([currentUserEmail])
                ], forDocument: targetUserRef)
                
                DispatchQueue.main.async {
                    Task {
                        _ = try await self.loadUsersInfoByEmail(emails: [targetUserEmail])
                        
                        self.isFollowingStatus[targetUserEmail] = true
                    }
                }
                return nil
            }
            
            print("Successfully followed \(targetUserEmail)")
        } catch {
            print("Error following user: \(error)")
        }
    }
    
    // 언팔로우 로직
    func unfollowUser(targetUserEmail: String) async {
        let db = Firestore.firestore()

        let currentUserEmail = authManager.email
        guard !targetUserEmail.isEmpty else {
            print("Target user email is empty.")
            return
        }
        
        let currentUserRef = db.collection("User").document(currentUserEmail)
        let targetUserRef = db.collection("User").document(targetUserEmail)
        
        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                // 현재 유저의 followings에서 타겟 유저 제거
                transaction.updateData([
                    "followings": FieldValue.arrayRemove([targetUserEmail])
                ], forDocument: currentUserRef)
                
                // 타겟 유저의 followers에서 현재 유저 제거
                transaction.updateData([
                    "followers": FieldValue.arrayRemove([currentUserEmail])
                ], forDocument: targetUserRef)
                
                DispatchQueue.main.async {
                    self.isFollowingStatus[targetUserEmail] = false
                }
                return nil
            }
            
            print("Successfully unfollowed \(targetUserEmail)")
        } catch {
            print("Error unfollowing user: \(error)")
        }
    }
    
    // 내가 특정 유저를 팔로우하고 있는지 확인
    func checkIfFollowing(targetUserEmail: String) async -> Bool {
        let currentUserEmail = authManager.email

        let db = Firestore.firestore()
        let document = try? await db.collection("User").document(currentUserEmail).getDocument()
        
        if let data = document?.data(), let followings = data["followings"] as? [String] {
            return followings.contains(targetUserEmail)
        } else {
            return false
        }
    }
    
    // 특정 유저가 나를 팔로우하고 있는지 확인
    func checkIfFollowedBy(targetUserEmail: String) async -> Bool {
        let currentUserEmail = authManager.email

        let db = Firestore.firestore()
        let document = try? await db.collection("User").document(targetUserEmail).getDocument()
        
        if let data = document?.data(), let followers = data["followings"] as? [String] {
            return followers.contains(currentUserEmail)
        } else {
            return false
        }
    }
    
    // 특정 유저의 팔로우 실시간 감지(리스너 활용)
    func observeUserFollowData(email: String) {
        let db = Firestore.firestore()
        let userDocRef = db.collection("User").document(email)
        
        listener = userDocRef.addSnapshotListener { [weak self] snapshot, error in
            guard let document = snapshot, document.exists else {
                print("User document does not exist")
                return
            }
            
            guard let docData = document.data() else {
                print("No user data found")
                return
            }
            
            if let followings = docData["followings"] as? [String] {
                self?.followingsCount = followings.count
            }
            
            if let followers = docData["followers"] as? [String] {
                self?.followersCount = followers.count
            }
        }
    }
    
    func removeListener() {
        listener?.remove()
        listener = nil
    }
    
    // 팔로워, 팔로잉 목록 불러오고 각 메모 및 칼럼 개수 로드 함수
    func loadFollowersAndFollowings(for userInfo: UserInfo) async {
        do {
            // 팔로워
            followers = try await loadUsersInfoByEmail(emails: userInfo.followers)
            for follower in followers {
                memoCount[follower.email] = try await getMemoCount(email: follower.email)
                columnCount[follower.email] = try await getColumnCount(email: follower.email)
            }
            
            // 팔로잉
            followings = try await loadUsersInfoByEmail(emails: userInfo.followings)
            for following in followings {
                memoCount[following.email] = try await getMemoCount(email: following.email)
                columnCount[following.email] = try await getColumnCount(email: following.email)
            }
            
            // 로드 후 로그 출력
            print("Updated followers: \(followers)")
            print("Updated followings: \(followings)")
        } catch {
            print("Error loading followers or followings: \(error.localizedDescription)")
        }
    }
    
    // 로그인된 유저가 각 유저를 팔로우하고 있는지 여부를 확인하는 함수
    func loadFollowingStatus() async {
        for follower in followers {
            isFollowingStatus[follower.email] = await checkIfFollowing(targetUserEmail: follower.email)
        }
        
        for following in followings {
            isFollowingStatus[following.email] = await checkIfFollowing(targetUserEmail: following.email)
        }
    }
    
    // MARK: - Block 관련 로직
    // 차단
    func blockUser(blockedEmail: String) async throws {
        guard let currentUserEmail = userInfo?.email else { return }
        let db = Firestore.firestore()
        let currentUserRef = db.collection("User").document(currentUserEmail)
        let blockedUserRef = db.collection("User").document(blockedEmail)

        _ = try await db.runTransaction { (transaction, errorPointer) -> Any? in
            do {
                let currentUserSnapshot = try transaction.getDocument(currentUserRef)
                guard let currentUserData = currentUserSnapshot.data() else { return nil }
                
                let blockedUserSnapshot = try transaction.getDocument(blockedUserRef)
                guard let blockedUserData = blockedUserSnapshot.data() else { return nil }
                
                var currentUserFollowings = currentUserData["followings"] as? [String] ?? []
                var currentUserFollowers = currentUserData["followers"] as? [String] ?? []
                var currentUserBlocked = currentUserData["blocked"] as? [String] ?? []
                
                var blockedUserFollowings = blockedUserData["followings"] as? [String] ?? []
                var blockedUserFollowers = blockedUserData["followers"] as? [String] ?? []
                
                // 이미 차단된 유저가 아닌지 확인 (중복 차단 방지)
                if !currentUserBlocked.contains(blockedEmail) {
                    currentUserFollowings.removeAll { $0 == blockedEmail }
                    currentUserFollowers.removeAll { $0 == blockedEmail }
                    
                    blockedUserFollowers.removeAll { $0 == currentUserEmail }
                    blockedUserFollowings.removeAll { $0 == currentUserEmail }

                    currentUserBlocked.append(blockedEmail)
                    
                    transaction.updateData([
                        "blocked": currentUserBlocked,
                        "followings": currentUserFollowings,
                        "followers": currentUserFollowers
                    ], forDocument: currentUserRef)
                    
                    transaction.updateData([
                        "followings": blockedUserFollowings,
                        "followers": blockedUserFollowers
                    ], forDocument: blockedUserRef)
                }
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            return nil
        }
        print("차단 성공")
    }
    
    // 차단 해제
    func unblockUser(blockedEmail: String) async throws {
        guard let currentUserEmail = userInfo?.email else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("User").document(currentUserEmail)
        
        _ = try await db.runTransaction { (transaction, errorPointer) -> Any? in
            do {
                let userSnapshot = try transaction.getDocument(userRef)
                guard let userData = userSnapshot.data() else { return nil }
                
                var blocked = userData["blocked"] as? [String] ?? []
                
                if blocked.contains(blockedEmail) {
                    blocked.removeAll { $0 == blockedEmail }
                    
                    transaction.updateData([
                        "blocked": blocked
                    ], forDocument: userRef)
                }
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            return nil
        }
        print("차단 해제 성공")
    }
    
    // 내가 특정 유저를 차단하고 있는지 확인
    func checkIfBlocked(targetUserEmail: String) async -> Bool {
        guard let currentUserEmail = userInfo?.email else {
            return false
        }
        
        let db = Firestore.firestore()
        let document = try? await db.collection("User").document(currentUserEmail).getDocument()
        
        if let data = document?.data(), let blocked = data["blocked"] as? [String] {
            return blocked.contains(targetUserEmail)
        } else {
            return false
        }
    }
    
    // 특정 유저가 나를 차단했는지 확인
    func checkIfBlockedByUser(targetUserEmail: String) async -> Bool {
        guard let currentUserEmail = userInfo?.email else {
            return false
        }
        
        let db = Firestore.firestore()
        let document = try? await db.collection("User").document(targetUserEmail).getDocument()
        
        if let data = document?.data(), let blocked = data["blocked"] as? [String] {
            return blocked.contains(currentUserEmail)
        } else {
            return false
        }
    }
}
