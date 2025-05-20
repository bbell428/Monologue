//
//  EllipsisCustomSheet.swift
//  Monologue
//
//  Created by Hyojeong on 10/18/24.
//

import SwiftUI

struct SheetButtonOption: Identifiable {
    let id: UUID = UUID()
    let type: ButtonOptionType // 버튼 이름
    let action: () -> Void // 버튼 액션
}

enum ReportOrDeleteTitle: String {
    case memo = "메모"
    case column = "칼럼"
    case comment = "댓글"
    case user = "회원"
}

enum ButtonOptionType: String {
    case share = "공유하기"
    case report = "신고하기"
    case block = "차단하기"
    case delete = "삭제하기"
    case cancel = "취소"
}

struct EllipsisCustomSheet: View {
    let buttonOptions: [SheetButtonOption] // 버튼 이름
    let sharedString: String? // 공유하고자 하는 String
    let sharedImage: Image = Image(.appLogo)
    let reportOrDeleteTitle: ReportOrDeleteTitle // 신고 or 삭제 대상

    @Binding var isShowingReportSheet: Bool
    @Binding var isShowingBlockAlert: Bool
    @Binding var isShowingEllipsisSheet: Bool
    @Binding var isShowingDeleteAlert: Bool
    var isBlocked: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(buttonOptions) { option in
                switch option.type {
                case .share:
                    ShareLink(
                        item: sharedImage,
                        preview: SharePreview(sharedString!, image: sharedImage)
                    ) {
                        Text(option.type.rawValue)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                    }
                    
                case .report:
                    Button {
                        isShowingReportSheet.toggle()
                    } label: {
                        Text(option.type.rawValue)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.red)
                    }
                    .sheet(isPresented: $isShowingReportSheet) {
                        ReportSheet(isShowingEllipsisSheet: $isShowingEllipsisSheet,
                                    isShowingReportSheet: $isShowingReportSheet,
                                    reportTitle: reportOrDeleteTitle,
                                    reportReason: nil)
                        .presentationDetents([.height(540), .large])
                    }
                    
                case .block:
                    Button {
                        isShowingEllipsisSheet.toggle()
                        isShowingBlockAlert.toggle()
                    } label: {
                        Text(isBlocked ? "차단 해제" : "차단하기")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.red)
                    }
                    
                case .delete:
                    Button {
                        isShowingDeleteAlert.toggle()
                    } label: {
                        Text(option.type.rawValue)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.red)
                    }
                    .alert(isPresented: $isShowingDeleteAlert) {
                        Alert(
                            title: Text("삭제하기"),
                            message: Text(getdeleteTitleText(for: reportOrDeleteTitle)),
                            primaryButton: .destructive(Text("삭제")) {
                                option.action()
                            },
                            secondaryButton: .cancel()
                        )
                    }

                case .cancel:
                    Button {
                        option.action()
                    } label: {
                        Text(option.type.rawValue)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                if option.type != .cancel {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.top, 20)
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    // deleteTitle에 따라 다른 텍스트를 반환하는 함수
    private func getdeleteTitleText(for title: ReportOrDeleteTitle) -> String {
        switch title {
        case .memo:
            return "이 \(title.rawValue)는 영구적으로 삭제되며 복원할 수 없습니다."
            
        case .column, .comment, .user:
            return "이 \(title.rawValue)은 영구적으로 삭제되며 복원할 수 없습니다."
        }
    }
}

// MARK: - 신고하는 이유 시트
enum ReportReason: String, CaseIterable {
    case commercial = "상업적 홍보 및 광고"
    case profanity = "비속어 및 욕설"
    case hateOrPorn = "혐오 및 음란 내용 신고"
    case spam = "도배 신고"
    case politicalOrControversial = "정치 및 분란 유도 신고"
    case other = "기타 문제 신고"
}

struct ReportSheet: View {
    @Binding var isShowingEllipsisSheet: Bool
    @Binding var isShowingReportSheet: Bool
    
    let reportTitle: ReportOrDeleteTitle
    let reportReason: ReportReason?
        
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(ReportCompleteSheet.getReportTitleText(for: reportTitle))
                    .font(.title2)
                    .bold()
                    .padding(.top, 50)
                
                Text("회원님의 신고는 익명으로 처리됩니다.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .padding(.top, -10)
                    .padding(.bottom, 10)
                
                Divider()
                
                // 신고 버튼 목록
                ForEach(ReportReason.allCases, id: \.self) { reason in
                    NavigationLink {
                        ReportCompleteSheet(reportReason: reason,
                                            reportTitle: reportTitle,
                                            isShowingEllipsisSheet: $isShowingEllipsisSheet,
                                            isShowingReportSheet: $isShowingReportSheet)
                    } label: {
                        HStack {
                            Text(reason.rawValue)
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Divider()
                }
            }
            .padding(.horizontal, 16)
            .foregroundStyle(.black)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

// MARK: - 신고 제출 시트
struct ReportCompleteSheet: View {
    @Environment(\.dismiss) private var dismiss
    let reportReason: ReportReason
    let reportTitle: ReportOrDeleteTitle
    @State private var customReason: String = ""
    @Binding var isShowingEllipsisSheet: Bool
    @Binding var isShowingReportSheet: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("신고를 제출합니다.")
                .font(.title2)
                .bold()
            
            Text("커뮤니티 가이드라인을 위반하는 콘텐츠만 삭제됩니다. 아래에서 신고 상세 정보를 검토하거나 수정할 수 있습니다.")
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .padding(.bottom, 10)
                .multilineTextAlignment(.center)
            
            Divider()
            
            Group {
                Text("신고 상세 정보")
                    .font(.headline)
                
                Text(ReportCompleteSheet.getReportTitleText(for: reportTitle))
                
                if reportReason.rawValue == ReportReason.other.rawValue {
                    TextField("자세한 신고 이유를 입력하세요.", text: $customReason)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.top, -10)
                } else {
                    Text(reportReason.rawValue)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                        .padding(.top, -12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Button {
                dismiss()
                isShowingEllipsisSheet = false
                isShowingReportSheet = false
            } label: {
                Text("제출")
                    .frame(maxWidth: .infinity, minHeight: 35)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.bottom, 10)
        .padding(.horizontal, 16)
        .navigationBarBackButtonHidden(true)
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
            setupNavigationBarAppearance(backgroundColor: .white)
        }
    }
    
    // reportTitle에 따라 다른 텍스트를 반환하는 함수
    public static func getReportTitleText(for title: ReportOrDeleteTitle) -> String {
        switch title {
        case .memo:
            return "이 \(title.rawValue)를 신고하는 이유"
        case .column, .comment, .user:
            return "이 \(title.rawValue)을 신고하는 이유"
        }
    }
}

#Preview() {
    EllipsisCustomSheet(buttonOptions: [SheetButtonOption(type: .share, action: { print("공유하기 clicked") }),
                                        SheetButtonOption(type: .block, action: { print("차단하기 clicked") }),
                                        SheetButtonOption(type: .report, action: { print("신고하기 clicked") }),
                                        SheetButtonOption(type: .delete, action: { print("삭제하기 clicked") }),
                                        SheetButtonOption(type: .cancel, action: { print("취소 clicked") })],
                        sharedString: "모노로그 화이팅",
                        reportOrDeleteTitle: .memo,
                        isShowingReportSheet: .constant(false),
                        isShowingBlockAlert: .constant(false),
                        isShowingEllipsisSheet: .constant(false),
                        isShowingDeleteAlert: .constant(false), isBlocked: false)
}

#Preview("ReportSheet") {
    ReportSheet(isShowingEllipsisSheet: .constant(false), isShowingReportSheet: .constant(false), reportTitle: .column, reportReason: .commercial)
}

#Preview("ReportCompleteSheet") {
    ReportCompleteSheet(reportReason: .commercial, reportTitle: .column, isShowingEllipsisSheet: .constant(false), isShowingReportSheet: .constant(false))
}
