//
//  BlockedUsersListView.swift
//  Monologue
//
//  Created by Hyojeong on 10/15/24.
//

import SwiftUI

struct BlockedUsersListView: View {
    @EnvironmentObject var userInfoStore: UserInfoStore
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
//    @State private var blockedUsers: [UserInfo] = []
    @State private var isActionActive = true // 차단 상태 관리
    
    @State private var memoCount: [String: Int] = [:] // 이메일별 메모 개수 저장
    @State private var columnCount: [String: Int] = [:] // 이메일별 칼럼 개수 저장
    
    var body: some View {
        ZStack {
            Color(.background)
                .ignoresSafeArea()
            
            ScrollView {
                if userInfoStore.blockedUsers.isEmpty {
                    VStack {
                        Text("차단한 사용자가 없습니다.")
                            .padding(.top, 250)
                    }
                } else {
                    VStack {
                        ForEach(userInfoStore.blockedUsers, id: \.self) { blockedUser in
                            NavigationLink {
                                MyPageView(userInfo: blockedUser)
                            } label: {
                                UserRow(
                                    profileImageName: blockedUser.profileImageName,
                                    nickname: blockedUser.nickname,
                                    memoCount: memoCount[blockedUser.email] ?? 0,
                                    columnCount: columnCount[blockedUser.email] ?? 0,
                                    isActionActive: $isActionActive,
                                    activeButtonText: "차단",
                                    inactiveButtonText: "차단 해제",
                                    onActive: {
                                        // 차단 로직
                                        Task {
                                            try await userInfoStore.blockUser(blockedEmail: blockedUser.email)
                                            await loadBlockedUsersAndCounts()
                                        }
                                    },
                                    onInactive: {
                                        // 차단 해제 로직
                                        Task {
                                            try await userInfoStore.unblockUser(blockedEmail: blockedUser.email)
                                            await loadBlockedUsersAndCounts()
                                        }
                                    },
                                    isFollowAction: false
                                )
                            }
                        }
                    }
                }
            }
            .padding(.top, 25)
            .padding(.horizontal, 16)
            .foregroundStyle(.accent)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle("차단 유저 목록")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // 기본 백 버튼 숨기기
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                }
            }
        }
        .onAppear {
            Task {
                await loadBlockedUsersAndCounts()
                await userInfoStore.loadUserInfo(email: authManager.email)
                
                await userInfoStore.blockedUsers = try userInfoStore.loadUsersInfoByEmail(emails: userInfoStore.userInfo?.blocked ?? [])
            }
        }
    }
    
    // 블락 유저 목록 및 해당 유저의 메모, 칼럼 개수 로드하는 함수
    private func loadBlockedUsersAndCounts() async {
        if let userInfo = userInfoStore.userInfo {
            do {
                userInfoStore.blockedUsers = try await userInfoStore.loadUsersInfoByEmail(emails: userInfo.blocked)
                
                for blockedUser in userInfoStore.blockedUsers {
                    memoCount[blockedUser.email] = try await userInfoStore.getMemoCount(email: blockedUser.email)
                    print("\(blockedUser.email)")
                    columnCount[blockedUser.email] = try await userInfoStore.getColumnCount(email: blockedUser.email)
                }
            } catch {
                print("Error loading blocked users or counts: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        BlockedUsersListView()
            .environmentObject(UserInfoStore())
    }
}
