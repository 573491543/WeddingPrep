import SwiftUI
import SwiftData

struct MaterialView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var materials: [MaterialItem]

    @State private var searchText = ""
    @State private var selectedTab: MaterialListType = .purchase
    @State private var selectedCategoryIndex = 0
    @State private var showAddSheet = false
    @State private var editingMaterial: MaterialItem?

    private var categoryTitles: [String] {
        ["全部"] + MaterialCategory.allCases.map { $0.rawValue }
    }

    private var filteredMaterials: [MaterialItem] {
        var filtered = materials.filter { $0.listType == selectedTab.rawValue }

        if selectedCategoryIndex > 0 {
            let category = MaterialCategory.allCases[selectedCategoryIndex - 1]
            filtered = filtered.filter { $0.category == category.rawValue }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.channel.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    private var totalItems: Int { filteredMaterials.count }
    private var purchasedItems: Int { filteredMaterials.filter { $0.status == MaterialStatus.purchased.rawValue }.count }
    private var pendingItems: Int { filteredMaterials.filter { $0.status == MaterialStatus.notPurchased.rawValue }.count }

    private var totalEstimate: Double {
        filteredMaterials.reduce(0) { $0 + $1.totalPrice }
    }
    private var spentAmount: Double {
        filteredMaterials.filter { $0.status == MaterialStatus.purchased.rawValue }.reduce(0) { $0 + $1.totalPrice }
    }
    private var pendingAmount: Double {
        filteredMaterials.filter { $0.status == MaterialStatus.notPurchased.rawValue }.reduce(0) { $0 + $1.totalPrice }
    }

    private var purchaseProgress: Double {
        guard totalItems > 0 else { return 0 }
        return Double(purchasedItems) / Double(totalItems)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab switch
                tabSwitch

                // Progress card
                progressCard

                // Search bar
                SearchBarView(text: $searchText, placeholder: "搜索物品、渠道、备注")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                // Category filter
                FilterChipScrollView(titles: categoryTitles, selectedIndex: $selectedCategoryIndex)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                // Material list
                if filteredMaterials.isEmpty {
                    EmptyStateView(icon: "list.clipboard", title: "暂无物资", subtitle: "点击右下角按钮添加物资")
                } else {
                    materialListView
                }
            }
            .background(AppTheme.bg)
            .navigationTitle("物资清单")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton {
                    showAddSheet = true
                }
                .padding(.trailing, 20)
                .padding(.bottom, 40)
            }
            .sheet(isPresented: $showAddSheet) {
                EditMaterialView(listType: selectedTab)
            }
            .sheet(item: $editingMaterial) { material in
                EditMaterialView(material: material)
            }
            .onReceive(NotificationCenter.default.publisher(for: .addMaterial)) { _ in
                showAddSheet = true
            }
        }
    }

    // MARK: - Tab Switch
    private var tabSwitch: some View {
        HStack(spacing: 0) {
            tabButton(title: "采购物资清单", isSelected: selectedTab == .purchase) {
                selectedTab = .purchase
                selectedCategoryIndex = 0
            }
            tabButton(title: "当日随身物品", isSelected: selectedTab == .carry) {
                selectedTab = .carry
                selectedCategoryIndex = 0
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func tabButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.smallCaption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : AppTheme.secondaryText)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? AppTheme.primaryColor : Color.clear)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Progress Card
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("采购进度")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                Text("共 \(totalItems) 项 · 待完成 \(pendingItems) 项")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }

            ProgressBarView(progress: purchaseProgress, height: 8, color: AppTheme.successColor)

            HStack {
                Text("预计花费 \(DateHelper.formatCurrency(totalEstimate))")
                    .font(AppTheme.smallCaption)
                    .foregroundColor(AppTheme.secondaryText)
                Spacer()
                Text("待花 \(DateHelper.formatCurrency(pendingAmount))")
                    .font(AppTheme.smallCaption)
                    .foregroundColor(AppTheme.accentColor)
            }
        }
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Material List
    private var materialListView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredMaterials, id: \.id) { material in
                    MaterialRowView(material: material) {
                        toggleMaterial(material)
                    } onTap: {
                        editingMaterial = material
                    }
                    .contextMenu {
                        Button {
                            editingMaterial = material
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            deleteMaterial(material)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }

    private func toggleMaterial(_ material: MaterialItem) {
        let newStatus = material.status == MaterialStatus.purchased.rawValue
            ? MaterialStatus.notPurchased.rawValue
            : MaterialStatus.purchased.rawValue
        material.status = newStatus
        material.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteMaterial(_ material: MaterialItem) {
        modelContext.delete(material)
        try? modelContext.save()
    }
}
