import SwiftUI

struct NotchContentView: View {
    var viewModel: NotchViewModel

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                NotchShape(
                    width: viewModel.currentWidth,
                    height: viewModel.currentHeight,
                    bottomRadius: viewModel.bottomCornerRadius
                )
                .fill(.black)
                .frame(
                    width: viewModel.currentWidth + 40,
                    height: max(viewModel.currentHeight, 1)
                )
                .opacity(viewModel.state == .collapsed ? 0 : 1)

                if viewModel.isExpanded {
                    ExpandedNotchView(viewModel: viewModel)
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                } else if viewModel.isHovering {
                    CollapsedNotchView(viewModel: viewModel)
                        .transition(.opacity)
                }
            }
            .animation(
                .spring(response: 0.35, dampingFraction: 0.7),
                value: viewModel.state
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
