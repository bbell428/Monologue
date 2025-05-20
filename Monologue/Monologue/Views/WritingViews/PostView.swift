//
//  PostView.swift
//  Monologue
//
//  Created by Hyunwoo Shin on 10/14/24.
//

import SwiftUI

struct PostView: View {
    @Environment(\.dismiss) var dismiss
    @State var selectedSegment: String = "메모" // 기본 세그먼트가 메모인 변수
    @EnvironmentObject private var memoStore: MemoStore
    @EnvironmentObject private var columnStore: ColumnStore
    @EnvironmentObject var userInfoStore: UserInfoStore
    @EnvironmentObject private var authManager:AuthManager
    @EnvironmentObject private var memoImageStore: MemoImageStore
    
    @Binding var selectedTab: Int   // MainView에서 바인딩 받는 변수, 탭 선택시 탭으로 넘어가는 변수
    @Binding var isPostViewActive: Bool // PostView로 이동 여부
    
    @State private var memoText: String = "" // 메모 텍스트
    @State private var columnText: String = "" // 칼럼 텍스트
    @State private var selectedFont: String = "San Francisco"
    @State private var selectedBackgroundImageName: String = "texture6"
    
    @State private var title: String = ""   // Column 제목
    @State private var selectedMemoCategories: [String] = ["오늘의 주제"]
    @State private var selectedColumnCategories: [String] = ["오늘의 주제"]
    @State private var lineCount: Int = 0 // memoText에서 라인을 카운트하는 변수
    
    @State private var userMemos: [Memo] = [] // 사용자가 작성한 메모들
    @State private var userColumns: [Column] = [] // 사용자가 작성한 칼럼들
    
    @State var cropArea: CGRect = .init(x: 0, y: 0, width: 100, height: 100)
    @State var imageViewSize: CGSize = .zero
    @State var croppedImage: UIImage?
    
    @State var textSize: CGFloat = 17
    @State private var textColor: Color = .black
    
    var body: some View {
        ZStack {
            Color(.background)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: {
                        selectedTab = 0
                        isPostViewActive = false
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                    }
                    Spacer()
                    Text("POST")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.accent)
                    Spacer()
                    Button(action: {
                        if selectedSegment == "메모" {
                            // 메모 저장 처리
                            let newMemo = Memo(content: memoText,
                                               email: userInfoStore.userInfo?.email ?? "",
                                               userNickname: userInfoStore.userInfo?.nickname ?? "",
                                               font: selectedFont,
                                               backgroundImageName: selectedBackgroundImageName,
                                               categories: selectedMemoCategories,
                                               likes: [],
                                               date: Date(),
                                               lineCount: lineCount,
                                               comments: [])
                            memoStore.addMemo(memo: newMemo) { error in
                                if let error = error {
                                    print("Error adding memo: \(error)")
                                } else {
                                    // 발핼버튼 클릭 시 HomeView로 이동하는 코드
                                    DispatchQueue.main.async {
                                        selectedTab = 0
                                    }
                                    restFields()
                                }
                            }
                            
                            if let croppedImage = self.crop(image: UIImage(named: selectedBackgroundImageName) ?? UIImage(), cropArea: cropArea, imageViewSize: imageViewSize) {
                                self.croppedImage = self.combineImage(croppedImage: croppedImage, text: memoText, imageViewSize: imageViewSize)
                                memoImageStore.UploadImage(image: self.croppedImage ?? UIImage(), imageName: newMemo.id)
                            }

                        } else if selectedSegment == "칼럼" {
                            let newColumn = Column(
                                title: title,
                                content: columnText,
                                email: userInfoStore.userInfo?.email ?? "",
                                userNickname: userInfoStore.userInfo?.nickname ?? "",
                                categories: selectedColumnCategories,
                                likes: [],
                                date: Date(),
                                comments: []
                            )
                            columnStore.addColumn(column: newColumn) { error in
                                if let error = error {
                                    print("Error adding column: \(error)")
                                } else {
                                    DispatchQueue.main.async {
                                        selectedTab = 0
                                    }
                                    restFields()
                                }
                            }
                        }
                    }) {
                        Text("발행")
                            
                    }
                    .disabled(memoText.isEmpty && selectedSegment == "메모" || columnText.isEmpty && selectedSegment == "칼럼")
                }
                .padding(.bottom, 5)
                .padding(.horizontal, 16)
                
                CustomSegmentView(segment1: "메모", segment2: "칼럼", selectedSegment: $selectedSegment)
                    .padding(.bottom, 5)
                
                ScrollView {
                    if selectedSegment == "메모" {
                        MemoWritingView(memoText: $memoText, selectedFont: $selectedFont, selectedMemoCategories: $selectedMemoCategories, selectedBackgroundImageName: $selectedBackgroundImageName, lineCount: $lineCount, cropArea: $cropArea, imageViewSize: $imageViewSize, textSize: $textSize, textColor: $textColor)
                            .padding(.top, 10)
                    } else if selectedSegment == "칼럼" {
                        ColumnWritingView(title: $title, columnText: $columnText, selectedColumnCategories: $selectedColumnCategories)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            Task {
                // 유저의 메모 로드
                memoStore.loadMemosByUserEmail(email: authManager.email) { memos, error in
                    if let memos = memos {
                        userMemos = memos
                    }
                }
                
                // 유저의 칼럼 로드
                columnStore.loadColumnsByUserEmail(email: authManager.email) { columns, error in
                    if let columns = columns {
                        userColumns = columns
                    }
                }
            }
        }
        // 세그먼트 변경 시 버튼이 초기화 하는 코드
        .onChange(of: selectedSegment) { newSegment in
            
            selectedMemoCategories = ["오늘의 주제"]
            selectedColumnCategories = ["오늘의 주제"]
            
            if newSegment == "메모" {
                selectedFont = "San Francisco"
                selectedBackgroundImageName = "texture6"
            }
        }
    }
    // 발핼버튼 클릭 시 적은 내용이 사라지고, 메모 글쓰기로 가면 버튼이 디폴트로되어있는 함수
    private func restFields() {
        title = ""
        memoText = ""
        columnText = ""
        selectedMemoCategories = ["오늘의 주제"]
        selectedColumnCategories = ["오늘의 주제"]
        
        if selectedSegment == "메모" {
            selectedFont = "San Francisco"
            selectedBackgroundImageName = "texture6"
        }
    }
    
    private func crop(image: UIImage, cropArea: CGRect, imageViewSize: CGSize) -> UIImage? {
        
        let scaleX = image.size.width / imageViewSize.width * image.scale
        let scaleY = image.size.height / imageViewSize.height * image.scale
        let scaledCropArea = CGRect(
            x: cropArea.origin.x * scaleX,
            y: cropArea.origin.y * scaleY,
            width: cropArea.size.width * scaleX,
            height: cropArea.size.height * scaleY
        )
        
        guard let cutImageRef: CGImage = image.cgImage?.cropping(to: scaledCropArea) else {
            return nil
        }
        
        return UIImage(cgImage: cutImageRef)
    }
    
    private func combineImage(croppedImage: UIImage, text: String, imageViewSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: croppedImage.size)
        
        return renderer.image { context in
            croppedImage.draw(at: .zero)
            
            let fontSize: CGFloat = textSize
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: selectedFont, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor(textColor)
            ]
            
            let textRect = CGRect(
                x: 5,
                y: 8,
                width: croppedImage.size.width - 10,
                height: croppedImage.size.height - 16
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}

//#Preview {
//    PostView()
//        .environmentObject(AuthManager())
//        .environmentObject(UserInfoStore())
//        .environmentObject(MemoStore())
//        .environmentObject(ColumnStore())
//        .environmentObject(CommentStore())
//        .environmentObject(MemoImageStore())
//}
