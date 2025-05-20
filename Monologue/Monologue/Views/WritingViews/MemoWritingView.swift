//
//  MemoWritingView.swift
//  Monologue
//
//  Created by Min on 10/15/24.
//

import SwiftUI


struct MemoWritingView: View {
    
    
    @Binding var memoText: String
    @Binding var selectedFont: String
    @Binding var selectedMemoCategories: [String]
    @Binding var selectedBackgroundImageName: String
    @Binding var lineCount: Int
    @State private var textLimit: Int = 500
    
    // FocusState 변수를 선언하여 TextEditor의 포커스 상태를 추적
    @FocusState private var isTextEditorFocused: Bool
    
    @StateObject private var memoStore = MemoStore()
    @EnvironmentObject var userInfoStore: UserInfoStore
    @EnvironmentObject private var authManager: AuthManager
    
    @Binding var cropArea: CGRect
    @Binding var imageViewSize: CGSize
    
    let rows = [GridItem(.fixed(50))]
    
    let placeholder: String = "문장을 입력해 주세요."
    let fontOptions = ["기본서체",  "노트셰리프", "고펍바탕", "나눔스퀘어", "나눔바른펜"]
    let fontFileNames = ["San Francisco", "NotoSerifKR-Regular", "KoPubWorldBatangPM", "NanumSquareOTFR", "NanumBarunpenOTF"] // 폰트 파일 이름
    
    let categoryOptions = ["오늘의 주제", "에세이", "사랑", "자연", "시", "자기계발", "추억", "소설", "SF", "IT", "기타"]
    let backgroundImageNames = ["texture1", "texture2", "texture3", "texture4", "texture5", "texture6"]
    
    let lineHeight: CGFloat = 24
    
    
    @State private var showImagePicker = false // 이미지 선택 Sheet 표시 여부
    @State private var uploadedImage: UIImage? // 업로드된 이미지를 저장
    
    @Binding var textSize: CGFloat
    @Binding var textColor: Color
    
    var body: some View {
        VStack {
            VStack {
                ZStack {
                    if let image = UIImage(contentsOfFile: selectedBackgroundImageName) { // 파일 경로에서 이미지 로드
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 500)
                            .cornerRadius(8)
                            .clipped()
                            .overlay(alignment: .topLeading) {
                                GeometryReader { geometry in
                                    CropBox(rect: $cropArea, text: $memoText, selectedFont: $selectedFont, placeholder: placeholder, textSize: $textSize, textColor: $textColor)
                                        .focused($isTextEditorFocused)
                                        .onReceive(memoText.publisher.collect()) { newValue in
                                            if newValue.count > textLimit {
                                                memoText = String(newValue.prefix(textLimit))
                                            }
                                        }
                                        .onAppear {
                                            self.imageViewSize = geometry.size
                                        }
                                        .onChange(of: geometry.size) {
                                            self.imageViewSize = $0
                                        }
                                }
                            }
                            .overlay (
                                Rectangle()
                                    .stroke(Color.gray, lineWidth: 3)
                            )
                    } else {
                        Image(selectedBackgroundImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 500)
                            .cornerRadius(8)
                            .clipped()
                            .overlay(alignment: .topLeading) {
                                GeometryReader { geometry in
                                    CropBox(rect: $cropArea, text: $memoText, selectedFont: $selectedFont, placeholder: placeholder, textSize: $textSize, textColor: $textColor)
                                        .focused($isTextEditorFocused)
                                        .onReceive(memoText.publisher.collect()) { newValue in
                                            if newValue.count > textLimit {
                                                memoText = String(newValue.prefix(textLimit))
                                            }
                                        }
                                        .onAppear {
                                            self.imageViewSize = geometry.size
                                        }
                                        .onChange(of: geometry.size) {
                                            self.imageViewSize = $0
                                        }
                                }
                            }
                            .overlay (
                                Rectangle()
                                    .stroke(Color.gray, lineWidth: 3)
                            )
                    }
                }
                
            }
            .padding(.horizontal, 16)
            
            HStack {
                HStack(spacing: 8) {
                    ForEach([Color.black ,Color.red, Color.green, Color.blue, Color.orange, Color.purple], id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 18, height: 18)
                                .onTapGesture {
                                    textColor = color // 선택한 색상으로 텍스트 색상 변경
                                }
                        }
                    }
                Spacer()
                Text("\(memoText.count)/500")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom)
            .padding(.horizontal, 16)
            
            HStack(spacing: 10) {
                Image(systemName: "textformat.size")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color.accent)
                
                Text("크기")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Color.accent)
                
                Slider(value: $textSize, in: 1...50, step: 1) {
                    Text("텍스트 크기 조절 슬라이더")
                }
                
                Text("\(Int(textSize))")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.accent)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            Divider()
            
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "a.square")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color.accent)
                    
                    Text("글꼴")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Color.accent)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: rows, spacing: 10) {
                            ForEach(Array(zip(fontOptions.indices, fontOptions)), id: \.0) { index, font in
                                FontButton(title: font, isSelected: selectedFont == fontFileNames[index], selectedFont: fontFileNames[index]) {
                                    selectedFont = fontFileNames[index] // 해당 폰트 파일로 변경
                                } onFocusChange: {
                                    isTextEditorFocused = false // 포커스를 해제하여 키보드를 내리기
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                }
            }
            .padding(.leading, 16)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $uploadedImage) // ImagePicker 호출
            }
            .onChange(of: uploadedImage) { newImage in
                if let image = newImage {
                    applyUploadedImage(image)
                }
            }
            
            Divider()
            
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "squareshape.split.2x2.dotted")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color.accent)
                    
                    Text("배경")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.accent)
                    
                    // 사진 업로드 버튼
                    Button(action: {
                        showImagePicker = true // Sheet 열기
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .frame(width: 30, height: 30)
                            .background(Color.background)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.brown, lineWidth: 1) // 테두리 추가
                            )
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: rows, spacing: 10) {
                            ForEach(backgroundImageNames, id: \.self) { imageName in
                                BackgroundButton(imageName: imageName) {
                                    selectedBackgroundImageName = imageName
                                } onFocusChange: {
                                    isTextEditorFocused = false
                                }
                            }
                            .padding(.horizontal, 10)
                        }
                    }
                }
            }
            .padding(.leading, 16)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $uploadedImage)
            }
            .onChange(of: uploadedImage) { newImage in
                if let image = newImage {
                    applyUploadedImage(image) // 업로드된 이미지를 처리
                }
            }
            
            Divider()
            HStack {
                Image(systemName: "exclamationmark.circle") // 경고 아이콘
                    .foregroundColor(Color(.systemGray2))
                Text("카테고리는 최대 3개만 선택 가능합니다.")
                    .font(.caption) // 크기와 굵기 조정
                    .foregroundStyle(Color(.systemGray2))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 5)
            .padding(.bottom, -2)
            
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "tag")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color.accent)
                    Text("카테고리")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.accent)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: rows, spacing: 10) {
                            ForEach(categoryOptions, id: \.self) { category in
                                CategoryMemoButton(title: category, isSelected: selectedMemoCategories.contains(category)) {
                                    // 선택된 카테고리가 포함되어 있으면 제거
                                    if selectedMemoCategories.contains(category) {
                                        selectedMemoCategories.removeAll { $0 == category }
                                    }
                                    // 선택된 카테고리 개수가 3개 미만일 때만 추가
                                    else if selectedMemoCategories.count < 3 {
                                        selectedMemoCategories.append(category)
                                    }
                                } onFocusChange: {
                                    isTextEditorFocused = false
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                    }
                }
            }
            .padding(.leading, 16)
        }
        .toolbar {
            // 키보드 위에 '완료' 버튼 추가
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    Spacer() // 왼쪽 공간을 확보하여 버튼을 오른쪽으로 이동
                    Button("완료") {
                        isTextEditorFocused = false // 키보드 숨기기
                    }
                }
            }
        }
        .contentShape(Rectangle()) // 전체 뷰가 터치 가능하도록 설정
        .onTapGesture {
            isTextEditorFocused = false // 다른 곳을 클릭하면 포커스 해제
        }
    }
    
    // TextEditor의 라인수를 계산하는 함수
    private func calculateLineCount(in width: CGFloat) {
        let size = CGSize(width: width, height: .infinity)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: selectedFont, size: 17) ?? UIFont.systemFont(ofSize: 17)
        ]
        let textHeight = (memoText as NSString).boundingRect(with: size, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil).height
        lineCount = Int(ceil(textHeight / lineHeight))
    }
    
    private func applyUploadedImage(_ image: UIImage) {
        // 이미지를 로컬 파일로 저장
        if let data = image.jpegData(compressionQuality: 0.8) {
            let filename = UUID().uuidString + ".jpg" // 고유 파일명 생성
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            
            do {
                try data.write(to: fileURL) // 파일 시스템에 저장
                selectedBackgroundImageName = fileURL.path // 경로를 selectedBackgroundImageName에 저장
            } catch {
                print("Error saving image: \(error)")
            }
        }
    }
}

// 폰트 버튼의 크기와 이름을 보여주는 뷰
struct FontButton: View {
    var title: String
    var isSelected: Bool
    var selectedFont: String
    var action: () -> Void
    var onFocusChange: () -> Void // 포커스 상태 변경을 위한 클로저 추가
    
    var body: some View {
        Button(action: {
            onFocusChange() // 포커스 상태 변경 호출
            action() // 기존의 action 실행
        }) {
            Text(title)
                .font(.custom(selectedFont, size: 13))
                .foregroundColor(isSelected ? .white : .brown)
                .frame(width: 70, height: 30)
                .background(isSelected ? Color.accentColor : Color.clear)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.brown, lineWidth: 1)
                )
        }
    }
}

// 백그라운드 이미지 버튼의 크기와 이름을 보여주는 뷰
struct BackgroundButton: View {
    var imageName: String
    var action: () -> Void
    var onFocusChange: () -> Void // 포커스 상태 변경을 위한 클로저 추가
    
    var body: some View {
        Button(action: {
            onFocusChange()
            action()
        }) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.brown, lineWidth: 1) // 테두리 추가
                )
        }
    }
}

// 카테고리 버튼의 크기와 이름을 보여주는 뷰
struct CategoryMemoButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    var onFocusChange: () -> Void
    
    var body: some View {
        Button(action: {
            onFocusChange()
            action()
        }) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isSelected ? .white : .brown)
                .frame(width: 70, height: 30)
                .background(isSelected ? Color.accentColor : Color.clear)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.brown, lineWidth: 1)
                )
        }
    }
}

//#Preview {
//    MemoWritingView(text: .constant(""), selectedFont: .constant("기본서체"), selectedMemoCategories: .constant([]), selectedBackgroundImageName: .constant("jery1"), lineCount: .constant(5))
//}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage? // 선택된 이미지를 바인딩
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary // 사진 라이브러리 사용
        picker.allowsEditing = true // 사진 편집 허용
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.presentationMode.wrappedValue.dismiss() // 선택 후 닫기
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss() // 취소 시 닫기
        }
    }
}
