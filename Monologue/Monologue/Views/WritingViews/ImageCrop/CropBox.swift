//
//  CropBox.swift
//  Monologue
//
//  Created by Hyunwoo Shin on 10/22/24.
//

import SwiftUI

struct CropBox: View {
    @Binding public var rect: CGRect
    @Binding public var text: String
    public let minSize: CGSize
    @Binding public var selectedFont: String
    public let placeholder: String
    
    @State private var initialRect: CGRect? = nil
    @State private var frameSize: CGSize = .zero
    @State private var draggedCorner: UIRectCorner? = nil
    
    let lineHeight: CGFloat = 24
    @Binding var textSize: CGFloat
    @Binding var textColor: Color
    
    public init(
        rect: Binding<CGRect>,
        text: Binding<String>,
        minSize: CGSize = .init(width: 100, height: 100),
        selectedFont: Binding<String>,
        placeholder: String,
        textSize: Binding<CGFloat>,
        textColor: Binding<Color>
    ) {
        self._rect = rect
        self._text = text
        self.minSize = minSize
        self._selectedFont = selectedFont
        self.placeholder = placeholder
        self._textSize = textSize
        self._textColor = textColor
    }
    
    private var rectDrag: some Gesture {
        DragGesture()
            .onChanged { gesture in
                if initialRect == nil {
                    initialRect = rect
                    draggedCorner = closestCorner(point: gesture.startLocation, rect: rect)
                }
                
                if let draggedCorner {
                    self.rect = dragResize(
                        initialRect: initialRect!,
                        draggedCorner: draggedCorner,
                        frameSize: frameSize,
                        translation: gesture.translation
                    )
                } else {
                    self.rect = drag(
                        initialRect: initialRect!,
                        frameSize: frameSize,
                        translation: gesture.translation
                    )
                }
            }
            .onEnded { gesture in
                initialRect = nil
                draggedCorner = nil
            }
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            blur
            box
            TextEditor(text: $text) // Add TextEditor for text input
                .foregroundStyle(textColor)
                .font(.custom(selectedFont, size: textSize))
                .frame(width: rect.width - 10, height: rect.height - 10)
                .background(Color.clear)
                .border(Color.blue, width: 1)
                .offset(x: rect.origin.x, y: rect.origin.y)
                .disabled(false) // Allow interaction
                .scrollContentBackground(.hidden)
                .padding(5)
                .gesture(rectDrag)
//                .onChange(of: text) { _ in
//                    let editWidth = geometry.size.width
//                    calculateLineCount(in: editWidth)
//                }
        }
        .background {
            GeometryReader { geometry in
                Color.clear
                    .onAppear { self.frameSize = geometry.size }
                    .onChange(of: geometry.size) { self.frameSize = $0 }
            }
        }
    }
    
    private var blur: some View {
        Color.black.opacity(0.5)
            .overlay(alignment: .topLeading) {
                Color.white
                    .frame(width: rect.width - 1, height: rect.height - 1)
                    .offset(x: rect.origin.x, y: rect.origin.y)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .drawingGroup()
            .blendMode(.multiply)
    }
    
    private var box: some View {
        ZStack {
            grid
            pins
        }
        .border(.blue, width: 2)
        .background(Color.white.opacity(0.001))
        .frame(width: rect.width, height: rect.height)
        .offset(x: rect.origin.x, y: rect.origin.y)
        .gesture(rectDrag)
    }
    
    private var pins: some View {
        VStack {
            HStack {
                pin(corner: .topLeft)
                Spacer()
                pin(corner: .topRight)
            }
            Spacer()
            HStack {
                pin(corner: .bottomLeft)
                Spacer()
                pin(corner: .bottomRight)
            }
        }
    }
    
    private func pin(corner: UIRectCorner) -> some View {
        var offX = 1.0
        var offY = 1.0
        
        switch corner {
        case .topLeft:      offX = -1;  offY = -1
        case .topRight:                 offY = -1
        case .bottomLeft:   offX = -1
        case .bottomRight: break
        default: break
        }
        
        return Circle()
            .fill(.blue)
            .frame(width: 16, height: 16)
            .offset(x: offX * 8, y: offY * 8)
    }
    
    private var grid: some View {
        ZStack {
            HStack {
                Spacer()
                Rectangle()
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                Spacer()
                Rectangle()
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                Spacer()
            }
            VStack {
                Spacer()
                Rectangle()
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                Spacer()
                Rectangle()
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .foregroundColor(.gray)
    }
    
    private func closestCorner(point: CGPoint, rect: CGRect, distance: CGFloat = 16) -> UIRectCorner? {
        let ldX = abs(rect.minX.distance(to: point.x)) < distance
        let rdX = abs(rect.maxX.distance(to: point.x)) < distance
        let tdY = abs(rect.minY.distance(to: point.y)) < distance
        let bdY = abs(rect.maxY.distance(to: point.y)) < distance
        
        guard (ldX || rdX) && (tdY || bdY) else { return nil }
        
        return if ldX && tdY { .topLeft }
        else if rdX && tdY { .topRight }
        else if ldX && bdY { .bottomLeft }
        else if rdX && bdY { .bottomRight }
        else { nil }
    }
    
    private func dragResize(initialRect: CGRect, draggedCorner: UIRectCorner, frameSize: CGSize, translation: CGSize) -> CGRect {
        var offX = 1.0
        var offY = 1.0
        
        switch draggedCorner {
        case .topLeft:      offX = -1;  offY = -1
        case .topRight:                 offY = -1
        case .bottomLeft:   offX = -1
        case .bottomRight: break
        default: break
        }
        
        let idealWidth = initialRect.size.width + offX * translation.width
        var newWidth = max(idealWidth, minSize.width)
        
        let maxHeight = frameSize.height - initialRect.minY
        let idealHeight = initialRect.size.height + offY * translation.height
        var newHeight = max(idealHeight, minSize.height)
        
        var newX = initialRect.minX
        var newY = initialRect.minY
        
        if offX < 0 {
            let widthChange = newWidth - initialRect.width
            newX = max(newX - widthChange, 0)
            newWidth = min(newWidth, initialRect.maxX)
        } else {
            newWidth = min(newWidth, frameSize.width - initialRect.minX)
        }
        
        if offY < 0 {
            let heightChange = newHeight - initialRect.height
            newY = max(newY - heightChange, 0)
            newHeight = min(initialRect.maxY, newHeight)
        } else {
            newHeight = min(newHeight, maxHeight)
        }
        
        return .init(origin: .init(x: newX, y: newY), size: .init(width: newWidth, height: newHeight))
    }
    
    private func drag(initialRect: CGRect, frameSize: CGSize, translation: CGSize) -> CGRect {
        let maxX = frameSize.width - initialRect.width
        let newX = min(max(initialRect.origin.x + translation.width, 0), maxX)
        let maxY = frameSize.height - initialRect.height
        let newY = min(max(initialRect.origin.y + translation.height, 0), maxY)
        
        return .init(origin: .init(x: newX, y: newY), size: initialRect.size)
    }
    
    private func calculateLineCount(in width: CGFloat) -> Int {
        let size = CGSize(width: width, height: .infinity)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: selectedFont, size: textSize) ?? UIFont.systemFont(ofSize: textSize)
        ]
        let textHeight = (text as NSString).boundingRect(with: size, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil).height
        
        let lineCount = Int(ceil(textHeight / lineHeight))
        
        return lineCount
    }
}
