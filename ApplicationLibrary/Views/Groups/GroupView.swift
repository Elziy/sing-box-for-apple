import Libbox
import Library
import SwiftUI

@MainActor
public struct GroupView: View {
    @State private var group: OutboundGroup
    @State private var geometryWidth: CGFloat = 300
    @State private var alert: Alert?
    @State private var iconIsScaledDown = false

    public init(_ group: OutboundGroup) {
        _group = State(initialValue: group)
    }

    private var title: some View {
        HStack {
            AsyncImage(url: URL(string: group.icon)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(iconIsScaledDown ? 0.9 : 1.0) // 0.8 表示缩小到原来的 80%
                    .animation(.easeInOut(duration: 0.2), value: iconIsScaledDown) // 动画效果
                    .onTapGesture {
                        Task {
                            await doURLTest()
                        }
                        withAnimation {
                            iconIsScaledDown = true // 先缩小
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                iconIsScaledDown = false // 再恢复原状
                            }
                        }
                    }
            } placeholder: {
                ProgressView()
            }
            .frame(width: 40, height: 40)

            VStack{
                Text(group.tag)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                Text(group.displayType)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(height: 40)
            .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 4))
            .onTapGesture {
                group.isExpand = !group.isExpand
                Task {
                    await setGroupExpand()
                }
            }

            VStack{
                Spacer()
                Text("\(group.items.count)")
                    .font(.headline)
                    .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(4)
                    .onTapGesture {
                        group.isExpand = !group.isExpand
                        Task {
                            await setGroupExpand()
                        }
                    }
            }
            #if os(macOS) || os(tvOS)
            .buttonStyle(.plain)
            #endif
        }
        .alertBinding($alert)
        .padding([.top, .bottom], 8)
    }

    public var body: some View {
        Section {
            if group.isExpand {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()),
                                         count: explandColumnCount()))
                {
                    ForEach(group.items, id: \.tag) { it in
                        GroupItemView($group, it)
                    }
                }
            } else {
                VStack(spacing: 20) {
                    ForEach(Array(itemGroups.enumerated()), id: \.offset) { items in
                        HStack(spacing: 20) {
                            ForEach(items.element, id: \.tag) { it in
                                ZStack {
                                    Circle()
                                        .fill(it.delayColor)
                                        .frame(width: 25, height: 25)
                                    if it.tag == group.selected {
                                        Circle()
                                            .fill(Color.white)
                                        #if !os(tvOS)
                                            .frame(width: 15, height: 15)
                                        #else
                                            .frame(width: 15, height: 15)
                                        #endif
                                    }
                                }
                                #if !os(tvOS)
                                .frame(width: 10, height: 10)
                                #else
                                .frame(width: 30, height: 30)
                                #endif
                            }
                        }.frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
        } header: {
            title
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background {
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .frame(height: 1)
                    .onChangeCompat(of: geometry.size.width) { newValue in
                        geometryWidth = newValue
                    }
                    .onAppear {
                        geometryWidth = geometry.size.width
                    }
            }.padding()
        }
    }

    private var itemGroups: [[OutboundGroupItem]] {
        let count: Int
        #if os(tvOS)
            count = Int(Int(geometryWidth) / 40)
        #else
            count = Int(Int(geometryWidth) / 28)
        #endif
        if count == 0 {
            return [group.items]
        } else {
            return group.items.chunked(
                into: count
            )
        }
    }

    private func explandColumnCount() -> Int {
        let standardCount = Int(Int(geometryWidth) / 180)
        #if os(iOS)
            return standardCount < 2 ? 2 : standardCount
        #elseif os(tvOS)
            return 4
        #else
            return standardCount < 1 ? 1 : standardCount
        #endif
    }

    private nonisolated func doURLTest() async {
        do {
            try await LibboxNewStandaloneCommandClient()!.urlTest(group.tag)
        } catch {
            await MainActor.run {
                alert = Alert(error)
            }
        }
    }

    private nonisolated func setGroupExpand() async {
        do {
            try await LibboxNewStandaloneCommandClient()!.setGroupExpand(group.tag, isExpand: group.isExpand)
        } catch {
            await MainActor.run {
                alert = Alert(error)
            }
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
