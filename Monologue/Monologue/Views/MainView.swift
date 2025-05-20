//
//  MainView.swift
//  Monologue
//
//  Created by Hyunwoo Shin on 10/14/24.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userInfoStore: UserInfoStore
    @State private var selectedTab: Int = 0
    @State private var isPostViewActive: Bool = false // PostView로 이동 여부

    var body: some View {
        TabView(selection: $selectedTab) {
            Group {
                HomeView(selectedTab: $selectedTab)
                    .tabItem {
                        VStack {
                            Image(systemName: "book.pages")
                            Text("Home")
                        }
                    }
                    .tag(0)
                
                NavigationStack {
                    // PostView로 자동 네비게이션
                    NavigationLink(destination: PostView(selectedTab: $selectedTab, isPostViewActive: $isPostViewActive), isActive: $isPostViewActive) {
                        EmptyView() // 실제로 화면에 보이지 않음
                    }
                }
                .tabItem {
                    VStack {
                        Image(systemName: "plus.circle")
                        Text("Post")
                    }
                }
                .tag(1)
                
                if let userInfo = userInfoStore.userInfo {
                    MyPageView(userInfo: userInfo)
                        .tabItem {
                            VStack {
                                Image(systemName: "person")
                                Text("My Page")
                            }
                        }
                        .tag(2)
                }
            }
            .toolbarBackground(Color.background, for: .tabBar)
        }
        .accentColor(.accent).ignoresSafeArea()
        .onAppear {
            Task {
                if authManager.email != "" {
                    await userInfoStore.loadUserInfo(email: authManager.email)
                    if let userInfo = userInfoStore.userInfo {
                        await userInfoStore.loadFollowersAndFollowings(for: userInfo)
                    }
                }
            }
            setupNavigationBarAppearance()
        }
        .onChange(of: selectedTab) { newValue in
            // Post 탭이 선택되면 PostView로 자동 이동
            if newValue == 1 {
                
                if !isPostViewActive {
                    isPostViewActive = true
                }
            } else {
                isPostViewActive = false
            }
        }
    }
}

#Preview {
    MainView()
}
